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
        self.activeStroke = PPStroke(color: UIColor.blackColor(), width: 5.0)
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        
        if (self.activeStroke!.points.count % 3 == 0){
            UIGraphicsBeginImageContext(self.frame.size)
            drawStroke(self.activeStroke!, quickly: true)
            self.setNeedsDisplay()
            UIGraphicsEndImageContext()
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
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
        
        stroke.color.setFill()
        for path in stroke.asBezierPaths(){
            path.fill()
        }
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
            p = 0
        } else {
            var lastPoint = points[points.count-1]
            var diff = sqrt(pow(location.x - lastPoint.location.x,2) + pow(location.y - lastPoint.location.y,2))
            p = max(0.4, min(1.0, diff / 50.0))
        }

        self.points.append(PPPoint(location: location, pressure: p))
    }
    
    func isDot() -> Bool{
        if points.count <= 2{
            return true
        } else if points.count <= 3 && (points.first!.location - points.last!.location).length() < 25{
            return true
        } else {
            return false
        }
    }
    
    func asBezierPaths() -> [UIBezierPath]{
        var paths = [UIBezierPath]()
        
        if self.isDot(){
            var dot = UIBezierPath()
            dot.addArcWithCenter(points.first!.location, radius: width*0.5, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
            paths.append(dot)
        } else {
            // Use Catmull-Rom interpolation to draw
            // Vary thickness based on pressure
            // With credit to https://github.com/andrelind/swift-catmullrom/
            // and http://code.tutsplus.com/tutorials/ios-sdk-advanced-freehand-drawing-techniques--mobile-15602
            
            // Generate two bounding paths to create stroke thickness
            var boundingPoints = [[points.first!.location, points.first!.location]]
            for var i = 0; i < points.count - 2; i++ {
                var startPoint = points[i]
                var endPoint = points[i+1]
                var smoothedPressure = (startPoint.pressure + endPoint.pressure)/2;
                var newPoints = pointsOnLineSegmentPerpendicularTo([startPoint.location, endPoint.location], length: smoothedPressure * self.width)
                boundingPoints.append(newPoints)
            }
            boundingPoints.append([points.last!.location, points.last!.location])
            
            // Make an initial path from the opening point
            var path = UIBezierPath()
            path.moveToPoint(boundingPoints[0][0])
            path.addLineToPoint(boundingPoints[1][0])
            path.addLineToPoint(boundingPoints[1][1])
            path.closePath()
            paths.append(path)
            
            // Generate the lines with Catmull-Rom interpolation and connect them
            var alpha = 0.5
            for var i = 1; i < boundingPoints.count - 2; ++i {
                var path = UIBezierPath()
                
                var controlPoints = controlPointsForCatmullRomCurve(
                    boundingPoints[i-1][0],
                    p1: boundingPoints[i][0],
                    p2: boundingPoints[i+1][0],
                    p3: boundingPoints[i+2][0]
                )

                path.moveToPoint(controlPoints[0])
                path.addCurveToPoint(controlPoints[3], controlPoint1: controlPoints[1], controlPoint2: controlPoints[2])
                
                controlPoints = controlPointsForCatmullRomCurve(
                    boundingPoints[i-1][1],
                    p1: boundingPoints[i][1],
                    p2: boundingPoints[i+1][1],
                    p3: boundingPoints[i+2][1]
                )
                
                path.addLineToPoint(controlPoints[3])
                path.addCurveToPoint(controlPoints[0], controlPoint1: controlPoints[2], controlPoint2: controlPoints[1])
                path.closePath()
                paths.append(path)
            }
            
            // Make a final path to the closing point
            path = UIBezierPath()
            path.moveToPoint(boundingPoints[boundingPoints.count - 2][0])
            path.addLineToPoint(boundingPoints[boundingPoints.count - 1][0])
            path.addLineToPoint(boundingPoints[boundingPoints.count - 2][1])
            path.closePath()
            paths.append(path)
        }
        
        return paths
    }
    
    func pointsOnLineSegmentPerpendicularTo(lineSegment:[CGPoint], length: CGFloat) -> [CGPoint]{
        var directionVector = lineSegment.first! - lineSegment.last!
        var adjustment = CGPointMake(directionVector.y, -directionVector.x)
        adjustment = adjustment * (Double(length) / adjustment.length())
        
        return [lineSegment.last! + adjustment, lineSegment.last! + (adjustment*(-1))]
    }
    
    func controlPointsForCatmullRomCurve(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3:CGPoint) -> [CGPoint]{
        let alpha = 0.5
        
        let d1 = (p1 - p0).length()
        let d2 = (p2 - p1).length()
        let d3 = (p3 - p2).length()
        
        var b1 = p2 * pow(d1, 2 * alpha)
        b1 = b1 - (p0 * pow(d2, 2 * alpha))
        b1 = b1 + (p1 * (2 * pow(d1, 2 * alpha) + 3 * pow(d1, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
        b1 = b1 * (1.0 / (3 * pow(d1, alpha) * (pow(d1, alpha) + pow(d2, alpha))))
        
        var b2 = p1 * pow(d3, 2 * alpha)
        b2 = b2 - (p3 * (pow(d2, 2 * alpha)))
        b2 = b2 + (p2 * (2 * pow(d3, 2 * alpha) + 3 * pow(d3, alpha) * pow(d2, alpha) + pow(d2, 2 * alpha)))
        b2 = b2 * (1.0 / (3 * pow(d3, alpha) * (pow(d3, alpha) + pow(d2, alpha))))
        
        return [p1, b1, b2, p2]
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


// MARK: CGPoint and vector stuff
extension CGPoint{
    func length() -> Double {
        return sqrt(CDouble(self.x*self.x + self.y*self.y))
    }
}

func +(left:CGPoint, right:CGPoint) -> CGPoint{
    return CGPointMake(left.x + right.x, left.y + right.y)
}

func -(left:CGPoint, right:CGPoint) -> CGPoint{
    return CGPointMake(left.x - right.x, left.y - right.y)
}

func *(left:CGPoint, scalar:Double) -> CGPoint{
    return CGPointMake(left.x * CGFloat(scalar), left.y * CGFloat(scalar))
}