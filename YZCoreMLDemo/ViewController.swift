//
//  ViewController.swift
//  YZCoreMLDemo
//
//  Created by Lester‘s Mac on 2021/8/28.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController {
    
    private lazy var topEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.8
        return view
    }()
    
    private lazy var bottomEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.8
        return view
    }()
    
    private lazy var bubbleLayer = YZBubbleLayer(string: "")
 
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var videoOutput = AVCaptureVideoDataOutput()
    
    //识别模型
    private lazy var requests: [VNRequest] = {
        do {
            //加载MLModel（训练好的模型），并做了一个让MLModel识别图像的请求
            let model = try VNCoreMLModel(for: Resnet50.init(configuration: MLModelConfiguration.init()).model)
            let classificationRequest = VNCoreMLRequest(model: model) {[weak self] (request, error) in
                self?.handleClassification(request, error)
            }
            //设置请求图像为方形的，此模型要求
            classificationRequest.imageCropAndScaleOption = .centerCrop
            return [classificationRequest]
        } catch {
            fatalError("加载模型错误:\(error.localizedDescription)")
        }
    }()
    //上一次时间
    private var lastDate: TimeInterval = 0
    private let timeInterval: TimeInterval = 0.33
    //未知结果次数
    private var unknownCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        view.addSubview(topEffectView)
        view.addSubview(bottomEffectView)
        bubbleLayer.opacity = 0
        bottomEffectView.contentView.layer.addSublayer(bubbleLayer)
        
        let effectH = (UIScreen.main.bounds.height - UIScreen.main.bounds.width) / 2
        topEffectView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(effectH)
        }
        
        bottomEffectView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(effectH)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bubbleLayer.position = CGPoint(x: view.bounds.width / 2, y: bottomEffectView.bounds.height / 2)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc private func backBtnClick() {
        dismiss(animated: true, completion: nil)
    }
    
    private func startSession() {
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        if let device = deviceDiscovery.devices.last {
            captureDevice = device
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoCapture"))
            
            captureSession.sessionPreset = .hd1920x1080
            captureSession.addOutput(videoOutput)
            
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession.addInput(input)
                captureSession.startRunning()
                
            } catch {
                print("录像启动错误：\(error.localizedDescription)")
            }
        }
        
    }
    
    private func handleClassification(_ request: VNRequest, _ error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]  else {
            print("unexpected result type from VNCoreMLRequest")
            return
        }
        guard let bestResult = observations.first else {
            print("classification didn't return any results")
            return
        }
        
        //如果识别结果为未知或者识别可信度小于0.5，不显示
        if bestResult.identifier.starts(with: "Unknown") || bestResult.confidence < 0.5 {
            if unknownCount < 3 {
                unknownCount += 1
            } else {
                unknownCount = 0
                DispatchQueue.main.async {
                    self.bubbleLayer.string = nil
                }
            }
            
        } else {
            unknownCount = 0
            DispatchQueue.main.async {
                self.bubbleLayer.string = bestResult.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentDate = Date.timeIntervalSinceReferenceDate
        if currentDate - lastDate < timeInterval {
            return
        }
        lastDate = currentDate
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        //执行这个请求--input进需要识别的图像
        let classifierRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        do {
            try classifierRequestHandler.perform(requests)
        } catch {
            print("识别功能错误:\(error)")
        }
        
    }
    
}
