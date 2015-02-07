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
    var redoStrokes = [PPStroke]()
    var activeStroke: PPStroke?
    var canvasThusFar: UIImage?
    var touchEvents = 0
//    var diagnosticsLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(patternImage: UIImage(named: "background.png")!)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        println("begain")
        self.activeStroke = PPStroke(color: UIColor.blackColor(), width: 10.0)
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        
        UIGraphicsBeginImageContext(self.frame.size)
        drawStroke(self.activeStroke!, quickly: true)
        self.setNeedsDisplay()
        UIGraphicsEndImageContext()
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        println("ended")
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        strokes.append(self.activeStroke!)
        self.activeStroke = nil
        self.setNeedsDisplay()
    }
    
    func drawStroke(stroke: PPStroke, quickly:Bool){
        if CGColorGetAlpha(stroke.color.CGColor) == 0 {
            // Eraser mode
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear)
        } else {
            // Pencil mode
            CGContextSetBlendMode(UIGraphicsGetCurrentContext() ,kCGBlendModeNormal)
        }
        
//        var circle = CAShapeLayer()
//        circle.strokeColor = stroke.color.CGColor
//        circle.path = stroke.asBezierPath().CGPath
//        circle.fillColor = stroke.color.CGColor
//        self.layer.addSublayer(circle)
        
        
        stroke.color.setFill()
        stroke.asBezierPath().stroke()
        
//        if (quickly){
//            var path = UIBezierPath()
//            path.moveToPoint(stroke.points.first!.location)
//            for point in stroke.points{
//                path.lineWidth = stroke.width * point.pressure
//                path.addLineToPoint(point.location)
//                path.stroke()
//                path = UIBezierPath()
//                path.moveToPoint(point.location)
//            }
//        } else {
//            var segment = [CGPoint]()
//            for point in stroke.points{
//                segment.append(point.location)
//                if segment.count == 5{
//                    var path = UIBezierPath()
//                    path.lineWidth = stroke.width * point.pressure
//                    
//                    // TODO: Catmull-Rom interpolation
//                    // https://github.com/andrelind/swift-catmullrom/
//                    // http://code.tutsplus.com/tutorials/ios-sdk_freehand-drawing--mobile-13164
//                    // http://code.tutsplus.com/tutorials/ios-sdk-advanced-freehand-drawing-techniques--mobile-15602
//                    
//                    // Use some weighted artificial smoothing
//                    segment[3] = CGPointMake(
//                        (segment[2].x+segment[4].x)/2.0*0.75 + segment[3].x*0.25,
//                        (segment[2].y+segment[4].y)/2.0*0.75 + segment[3].y*0.25
//                    )
//                    path.addCurveToPoint(segment[3], controlPoint1: segment[1], controlPoint2: segment[2])
//                    path.stroke()
//                    segment = [segment[3], segment[4]]
//                }
//            }
//            
//            // TODO: make sure we include last few points
//            // Finish drawing to the final point
//            var path = UIBezierPath()
//            path.lineWidth = stroke.width * stroke.points.last!.pressure
//            path.moveToPoint(segment[0])
//            path.addLineToPoint(segment.last!)
//            path.stroke()
//        }
    }
    
    override func drawRect(rect: CGRect) {
        if let sublayers = self.layer.sublayers{
            println("test")
            for layer in self.layer.sublayers{
                if let l = layer as? CALayer{
                    l.removeFromSuperlayer()
                }
            }
        }
        
//        (CGSize)drawAtPoint:(CGPoint)point withFont:(UIFont *)font
        
        if let stroke = activeStroke{
            // Only draw the most recent line
            if let cachedImage = canvasThusFar {
                cachedImage.drawInRect(rect)
            }
            drawStroke(stroke, quickly:true)
        } else {
            // Draw everything to a cached UIImage
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
            UIColor.whiteColor().setFill()
            UIBezierPath(rect: self.bounds).fill()
            for stroke in self.strokes{
                drawStroke(stroke, quickly: false)
            }
            canvasThusFar = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Draw result to screen
            canvasThusFar!.drawInRect(rect)
        }
    }
    
    func clear(){
        self.canvasThusFar = nil
        self.strokes = [PPStroke]()
        self.setNeedsDisplay()
    }
    
    func undo(){
        if self.strokes.count > 0{
            self.redoStrokes.append(self.strokes.removeLast())
            self.setNeedsDisplay()
        }
    }
    
    func redo(){
        if self.redoStrokes.count > 0{
            self.strokes.append(self.redoStrokes.removeLast())
            self.setNeedsDisplay()
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
        
        var p: CGFloat
        if points.count == 0{
            p = 1.0
        } else {
            var lastPoint = points[points.count-1]
            var diff = sqrt(pow(location.x - lastPoint.location.x,2) + pow(location.y - lastPoint.location.y,2))
            p = max(0.3, min(1.0, diff / 20.0))
        }

        self.points.append(PPPoint(location: location, pressure: p))
    }
    
    func asBezierPath() -> UIBezierPath{
        var path = UIBezierPath()
        path.lineWidth = self.width
        path.moveToPoint(points.first!.location)
        if points.count < 4 {
            // Draw simple straight lines
            for var i = 0; i < points.count - 1; ++i {
                path.addLineToPoint(points[i].location)
            }
        } else {
            // Use Catmull-Rom interpolation to draw
            // Vary thickness based on pressure
            // With credit to https://github.com/andrelind/swift-catmullrom/
            // and http://code.tutsplus.com/tutorials/ios-sdk-advanced-freehand-drawing-techniques--mobile-15602
            
            path.addLineToPoint(points[1].location)
            
            var alpha = 0.5
            for var i = 1; i < points.count - 2; ++i {
                let p0 = points[i-1].location
                let p1 = points[i].location
                let p2 = points[i+1].location
                let p3 = points[i+2].location
                
                let d1 = p1.deltaTo(p0).length()
                let d2 = p2.deltaTo(p1).length()
                let d3 = p3.deltaTo(p2).length()
                
                pow(d1, 2 * alpha)
                var b1 = p2.multiplyBy(pow(d1, 2 * alpha))
                b1 = b1.deltaTo(p0.multiplyBy(pow(d2, 2 * alpha)))
                b1 = b1.addTo(p1.multiplyBy(2 * pow(d1, 2 * alpha) + 3 * pow(d1, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
                b1 = b1.multiplyBy(1.0 / (3 * pow(d1, alpha) * (pow(d1, alpha) + pow(d2, alpha))))
                
                var b2 = p1.multiplyBy(pow(d3, 2 * alpha))
                b2 = b2.deltaTo(p3.multiplyBy(pow(d2, 2 * alpha)))
                b2 = b2.addTo(p2.multiplyBy(2 * pow(d3, 2 * alpha) + 3 * pow(d3, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
                b2 = b2.multiplyBy(1.0 / (3 * pow(d3, alpha) * (pow(d3, alpha) + pow(d2, alpha))))
                
                path.addCurveToPoint(p2, controlPoint1: b1, controlPoint2: b2)
            }
            path.addLineToPoint(points.last!.location)
            
            path.addLineToPoint(points.last!.location.addTo(CGPointMake(5, 1)))
            
            for var i = points.count - 2; i > 1; --i {
                let p0 = points[i+1].location.addTo(CGPointMake(5, 1))
                let p1 = points[i].location.addTo(CGPointMake(5, 1))
                let p2 = points[i-1].location.addTo(CGPointMake(5, 1))
                let p3 = points[i-2].location.addTo(CGPointMake(5, 1))
                
                let d1 = p1.deltaTo(p0).length()
                let d2 = p2.deltaTo(p1).length()
                let d3 = p3.deltaTo(p2).length()
                
                pow(d1, 2 * alpha)
                var b1 = p2.multiplyBy(pow(d1, 2 * alpha))
                b1 = b1.deltaTo(p0.multiplyBy(pow(d2, 2 * alpha)))
                b1 = b1.addTo(p1.multiplyBy(2 * pow(d1, 2 * alpha) + 3 * pow(d1, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
                b1 = b1.multiplyBy(1.0 / (3 * pow(d1, alpha) * (pow(d1, alpha) + pow(d2, alpha))))
                
                var b2 = p1.multiplyBy(pow(d3, 2 * alpha))
                b2 = b2.deltaTo(p3.multiplyBy(pow(d2, 2 * alpha)))
                b2 = b2.addTo(p2.multiplyBy(2 * pow(d3, 2 * alpha) + 3 * pow(d3, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
                b2 = b2.multiplyBy(1.0 / (3 * pow(d3, alpha) * (pow(d3, alpha) + pow(d2, alpha))))
                
                path.addCurveToPoint(p2, controlPoint1: b1, controlPoint2: b2)
            }
            path.addLineToPoint(points.first!.location.addTo(CGPointMake(5, 1)))
            
            path.closePath()
            path.usesEvenOddFillRule = true
        }
        
        return path
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

// Via https://github.com/andrelind/swift-catmullrom/
extension CGPoint{
    func deltaTo(a: CGPoint) -> CGPoint {
        return CGPointMake(self.x - a.x, self.y - a.y)
    }
    
    func length() -> Double {
        return sqrt(CDouble(self.x*self.x + self.y*self.y))
    }
    
    func multiplyBy(value:Double) -> CGPoint{
        return CGPointMake(self.x * CGFloat(value), self.y * CGFloat(value))
    }
    
    func addTo(a: CGPoint) -> CGPoint {
        return CGPointMake(self.x + a.x, self.y + a.y)
    }
}