//
//  PPCanvas.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/6/15.
//
//

import UIKit

class PPCanvas: UIView{
    var strokes = [PPStroke]()
    var activeStroke: PPStroke?
    var canvasThusFar: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(patternImage: UIImage(named: "background.png")!)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var activeStroke = PPStroke(color: UIColor.blackColor(), width: 2.0)
        activeStroke.addPoint(touches.anyObject() as UITouch, inView:self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        
//        strokes.append(finishedStroke)
//        activeStrokes.removeObjectForKey(key)
//        self.drawBitmap()
//        
        self.setNeedsDisplay()
    }
    
    func drawStroke(stroke: PPStroke){
        var path = UIBezierPath()
        path.lineWidth = stroke.width
        stroke.color.setStroke()
        path.moveToPoint(stroke.points.first!.location)
        
        var segment = [CGPoint]()
        for point in stroke.points{
            segment.append(point.location)
            if segment.count == 5{
                // Use bezier smoothing: code.tutsplus.com
                segment[3] = CGPointMake((segment[2].x+segment[4].x)/2.0, (segment[2].y+segment[4].y)/2.0)
                path.addCurveToPoint(segment[3], controlPoint1: segment[1], controlPoint2: segment[2])
                segment = [segment[3], segment[4]]
            }
        }
        
        // Finish drawing to the final point
        path.addLineToPoint(segment.last!)
       
        // Actually stroke the line
        path.stroke()
    }
    
    func drawBitmap(){
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        if let cachedImage = canvasThusFar {
            // We already have a cached image on screen
            cachedImage.drawAtPoint(CGPointZero)
        } else {
            // Draw a white background
            UIColor.whiteColor().setFill()
            UIBezierPath(rect: self.bounds).fill()
        }
        
        for stroke in self.strokes{
            drawStroke(stroke)
        }
        
        // Save current canvas state to bitmap
        canvasThusFar = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func drawRect(rect: CGRect) {
        if let cachedImage = canvasThusFar {
            cachedImage.drawInRect(rect)
        }
        for stroke in self.strokes{
            drawStroke(stroke)
        }
    }
}

// MARK: Data structures for storing sketch data

class PPStroke{
    let color: UIColor
    let width: CGFloat
    var points = [PPPoint]()
    
    init(color: UIColor!, width: CGFloat!){
        self.color = color
        self.width = width
    }
    
    func addPoint(touch: UITouch, inView: UIView){
        var location = touch.locationInView(inView)
        self.points.append(PPPoint(location: location, pressure: 1.0))
    }
}

class PPPoint: NSObject{
    let location: CGPoint
    let pressure: CGFloat
    
    init(location: CGPoint!, pressure: CGFloat!){
        self.location = location
        self.pressure = pressure
    }
}