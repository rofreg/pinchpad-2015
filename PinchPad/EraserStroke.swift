//
//  EraserStroke.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/19/16.
//
//

class EraserStroke: Stroke {
    required init(width: CGFloat!, color: UIColor!) {
        // Eraser strokes are wider and "white"
        super.init(width: width * 5.0, color: UIColor.whiteColor())
    }
    
    override func drawInView(view: UIView, quickly: Bool) {
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), CGBlendMode.Clear)
        super.drawInView(view, quickly: quickly)
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), CGBlendMode.Normal)
    }
}
