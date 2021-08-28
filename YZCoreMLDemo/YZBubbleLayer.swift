//
//  YZBubbleLayer.swift
//  YZCoreMLDemo
//
//  Created by Lester‘s Mac on 2021/8/28.
//

import UIKit

class YZBubbleLayer: CALayer {

    var string: String? {
        didSet {
            if (string == nil) {
                self.opacity = 0.0
            } else {
                textLayer.string = string
                self.opacity = 1.0
            }
            setNeedsLayout()
        }
    }
    var font: UIFont = UIFont(name: "Helvetica-Bold", size: 24.0)! {
        didSet {
            textLayer.font = font
            textLayer.fontSize = font.pointSize
        }
    }
    var textColor: UIColor = UIColor.white {
        didSet { textLayer.foregroundColor = textColor.cgColor }
    }
    var paddingHorizontal: CGFloat = 25.0 {
        didSet { setNeedsLayout() }
    }
    
    var paddingVertical: CGFloat = 10.0 {
        didSet { setNeedsLayout() }
    }
    
    var maxWidth: CGFloat = 300.0 {
        didSet { setNeedsLayout() }
    }

    private var textLayer = YZBubbleTextLayer()
    
    convenience init(string: String) {
        self.init()

        self.string = string

        backgroundColor = UIColor.systemPink.cgColor
        borderColor = UIColor.white.cgColor
        borderWidth = 3.5
        
        contentsScale = UIScreen.main.scale
        allowsEdgeAntialiasing = true
        
        textLayer.string = self.string
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.foregroundColor = textColor.cgColor
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.allowsFontSubpixelQuantization = true
        textLayer.isWrapped = true
        textLayer.updatePreferredSize(maxWidth: self.maxWidth - (paddingHorizontal * 2))
        textLayer.frame = CGRect(origin: CGPoint(x: paddingHorizontal, y: paddingVertical), size: textLayer.preferredFrameSize())
        addSublayer(textLayer)
        
        setNeedsLayout()
    }
    
    override func layoutSublayers() {

        textLayer.updatePreferredSize(maxWidth: self.maxWidth - (paddingHorizontal * 2))

        let preferredSize = preferredFrameSize()
        let diffSize = CGSize(width: frame.size.width - preferredSize.width, height: frame.size.height - preferredSize.height)
        frame = CGRect(origin: CGPoint(x: frame.origin.x + (diffSize.width / 2), y: frame.origin.y + (diffSize.height / 2)), size: preferredSize)
        cornerRadius = frame.height / 2.0

        textLayer.frame = CGRect(x: 0, y: paddingVertical, width: frame.width, height: frame.height)

    }
    
    override func preferredFrameSize() -> CGSize {
        let textLayerSize = textLayer.preferredFrameSize()
        return CGSize(width: textLayerSize.width + (paddingHorizontal * 2),
                      height: textLayerSize.height + (paddingVertical * 2))
    }
}
