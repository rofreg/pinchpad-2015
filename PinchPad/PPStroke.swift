//
//  PPStroke.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/8/15.
//
//

import UIKit

class PPStroke{
    let color: UIColor
    let width: CGFloat
    let tool: PPToolType
    var points = [PPPoint]()
    var cachedBezierPaths = [UIBezierPath]()
    var cachedPointsCount = 0
    var strokeSegmentsDrawn = 0
    
    init(tool: PPToolType!, width: CGFloat!, color: UIColor!){
        self.tool = tool
        self.width = width
        self.color = color
    }
    
    
    // MARK: Point management logic
    
    func addPoint(touch: UITouch, withPressure pressure: CGFloat, inView: UIView){
        var location = touch.locationInView(inView)
        self.addPoint(location, withPressure: pressure)
    }
    
    func addPoint(touch: UITouch, inView: UIView){
        var location = touch.locationInView(inView)
        self.addPoint(location)
    }
    
    func addPoint(location: CGPoint){
        // Fake pressure, simulated from velocity between points
        var p: CGFloat
        if points.count == 0{
            p = 0.55
        } else {
            var lastPoint = points[points.count-1]
            var diff = (location - lastPoint.location).length()
            p = max(0.55, min(1.0, CGFloat(diff) / 20.0))
        }
        
        self.addPoint(location, withPressure: p)
    }
    
    // TODO: thin out number of points around slow tight curves?
    func addPoint(location: CGPoint, withPressure pressure: CGFloat){
        // Do not add this point if it's too close to the last point
        if let lastPoint = self.points.last{
            if (lastPoint.location - location).length() < 4 {
                // TODO: handle pressure changes (i.e. I stayed still, but pressed down harder)
                return;
            }
        }
        
        self.points.append(PPPoint(location: location, pressure: pressure))
    }
    
    
    // MARK: Rendering logic
    
    func drawInView(view: UIView, quickly: Bool){
        self.color.setFill()
        self.color.setStroke()
        
        if (self.tool == PPToolType.Brush){
            // We need to do special handling for performance for the brush
            if (quickly){
                var paths = self.asBezierPaths()
                // Draw all but the very last segment (which is a dot, and might change later
                for var i = max(0, self.strokeSegmentsDrawn - 1); i < max(0, paths.count - 1); i++ {
                    paths[i].fill()
                }
                self.strokeSegmentsDrawn = paths.count - 1
            } else {
                for path in self.asBezierPaths(){
                    path.fill()
                }
                self.asBezierPath().stroke()
            }
        } else if (self.tool == PPToolType.Marker) {
            // For the marker, just draw the line
            self.asBezierPath(quickly: quickly).stroke()
        } else if (self.tool == PPToolType.Eraser) {
            // For the eraser, just draw the line
            UIColor.whiteColor().setStroke()
            self.asBezierPath(quickly: quickly).stroke()
        }
    }
    
    // Is this stroke just a dot?
    func isDot() -> Bool{
        if points.count <= 2{
            return true
        } else if points.count <= 3 && (points.first!.location - points.last!.location).length() < 25{
            // Count very quick taps as dots
            return true
        } else {
            return false
        }
    }
    
    // This returns a SINGLE BEZIER PATH connecting all points
    func asBezierPath(quickly: Bool = false) -> UIBezierPath{
        var path = UIBezierPath()
        path.lineWidth = self.width
        path.lineCapStyle = kCGLineCapRound
        path.lineJoinStyle = kCGLineJoinRound
        
        // Handle empty case
        if (self.points.count < 2){
            return path;
        }
        
        path.moveToPoint(self.points[0].location)
        path.addLineToPoint(self.points[1].location)
        
        // Generate any new segments with Catmull-Rom interpolation and connect them
        for var i = 1; i < self.points.count - 2; i++ {
            var controlPoints = controlPointsForCatmullRomCurve(
                self.points[i-1].location,
                p1: self.points[i].location,
                p2: self.points[i+1].location,
                p3: self.points[i+2].location
            )
            
            path.addCurveToPoint(controlPoints[3], controlPoint1: controlPoints[1], controlPoint2: controlPoints[2])
        }
        
        if (!quickly){
            path.addLineToPoint(self.points.last!.location)
        }
        
        return path
    }
    
    // TODO
    // https://developer.apple.com/library/mac/documentation/graphicsimaging/Reference/CGPath/Reference/reference.html#//apple_ref/c/func/CGPathCreateCopyByStrokingPath
    // http://stackoverflow.com/questions/16547572/generate-a-cgpath-from-another-paths-line-width-outline
    // http://stackoverflow.com/questions/24463832/ios-how-to-draw-a-stroke-with-an-outline
    
    // This returns a series of POLYGONS that simulate pressure
    func asBezierPaths() -> [UIBezierPath]{
        if cachedPointsCount == self.points.count {
            // This stroke hasn't changed since the last time we rendered it
            return cachedBezierPaths
        } else if self.isDot(){
            // This is just a dot
            var dot = UIBezierPath()
            dot.addArcWithCenter(points.first!.location, radius: width*0.5, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
            self.cachedBezierPaths = [dot]
        } else {
            // Let's calculate a fancy stroke!
            if (self.cachedBezierPaths.count > 0){
                // Remove the last segment of the cached path, as it should be recalculated
                self.cachedBezierPaths.removeLast()
            }
            
            // Use Catmull-Rom interpolation to draw
            // Vary thickness based on pressure
            // With credit to https://github.com/andrelind/swift-catmullrom/
            // and http://code.tutsplus.com/tutorials/ios-sdk-advanced-freehand-drawing-techniques--mobile-15602
            
            // Generate two bounding paths to create stroke thickness
            // First point needs a bit of special handling
            var startPoints = pointsOnLineSegmentPerpendicularTo([points[1].location, points[0].location], length: self.width * 0.5)
            var boundingPoints = [[startPoints[1], startPoints[0]]]
            
            // Now calculate all points in the middle of the path
            for var i = 0; i < points.count - 2; i++ {
                // Don't calculate data for already-cached segments
                if i >= max(0, self.cachedPointsCount - 4){
                    var startPoint = points[i]
                    var endPoint = points[i+1]
                    var nextPoint = points[i+2]
                    var smoothedPressure = (startPoint.pressure + endPoint.pressure + nextPoint.pressure)/3;
                    var newPoints = pointsOnLineSegmentPerpendicularTo([startPoint.location, endPoint.location], length: smoothedPressure * self.width)
                    
                    // If the line segments cross each other, as happens when we reverse direction,
                    // then we need to swap the two points to maintain a solid line
                    if let lastPoint = boundingPoints.last{
                        if lastPoint.count > 0{
                            if lineSegmentsIntersect(lastPoint[0], L1P2: newPoints[0], L2P1: lastPoint[1], L2P2: newPoints[1]){
                                var temp = newPoints[0]
                                newPoints[0] = newPoints[1]
                                newPoints[1] = temp
                            }
                        }
                    }
                    
                    boundingPoints.append(newPoints)
                } else {
                    boundingPoints.append([])
                }
            }
            
            // Now calculate our end points
            var endPoints = pointsOnLineSegmentPerpendicularTo([points[points.count - 2].location, points[points.count - 1].location], length: self.width * 0.5)
            boundingPoints.append([endPoints[0], endPoints[1]])
            
            // Make an initial path from the opening point, if we haven't already)
            if (self.cachedBezierPaths.count == 0){
                // Draw a dot at the starting location, to round the starting point off
                var path = UIBezierPath()
                path.addArcWithCenter(points.first!.location, radius: width*0.5, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
                self.cachedBezierPaths.append(path)
                
                // Add our first line segment
                path = UIBezierPath()
                path.moveToPoint(boundingPoints[0][0])
                path.addLineToPoint(boundingPoints[1][0])
                path.addLineToPoint(boundingPoints[1][1])
                path.addLineToPoint(boundingPoints[0][1])
                path.closePath()
                self.cachedBezierPaths.append(path)
            }
            
            // Generate any new segments with Catmull-Rom interpolation and connect them
            // (If we have cached segments, also make sure to re-draw the last cached segment
            for var i = max(1, self.cachedPointsCount - 2); i < boundingPoints.count - 2; i++ {
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
                self.cachedBezierPaths.append(path)
            }
            
            // Make a final path to the closing point
            var path = UIBezierPath()
            path.moveToPoint(boundingPoints[boundingPoints.count - 2][0])
            path.addLineToPoint(boundingPoints[boundingPoints.count - 1][0])
            path.addLineToPoint(boundingPoints[boundingPoints.count - 1][1])
            path.addLineToPoint(boundingPoints[boundingPoints.count - 2][1])
            path.closePath()
            self.cachedBezierPaths.append(path)
            
            // Draw a dot at the ending location, to round the ending point off
            path = UIBezierPath()
            path.addArcWithCenter(points.last!.location, radius: width*0.5, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
            self.cachedBezierPaths.append(path)
            
            // TODO: also stroke center set of lines with minimum width?
        }
        
        self.cachedPointsCount = self.points.count
        return self.cachedBezierPaths
    }
    
    func pointsOnLineSegmentPerpendicularTo(lineSegment:[CGPoint], length: CGFloat) -> [CGPoint]{
        var directionVector = lineSegment.first! - lineSegment.last!
        var adjustment = CGPointMake(directionVector.y, -directionVector.x)
        adjustment = adjustment * (Double(length) / adjustment.length())
        
        return [lineSegment.last! + adjustment, lineSegment.last! + (adjustment*(-1))]
    }
    
    // http://stackoverflow.com/questions/13394422/bezier-path-see-if-it-crosses
    func lineSegmentsIntersect(L1P1: CGPoint, L1P2: CGPoint, L2P1: CGPoint, L2P2: CGPoint) -> Bool
    {
        var x1 = L1P1.x, x2 = L1P2.x, x3 = L2P1.x, x4 = L2P2.x
        var y1 = L1P1.y, y2 = L1P2.y, y3 = L2P1.y, y4 = L2P2.y
        
        var bx = x2 - x1
        var by = y2 - y1
        var dx = x4 - x3
        var dy = y4 - y3
        
        var b_dot_d_perp = bx * dy - by * dx;
        
        if (b_dot_d_perp == 0) {
            return false
        }
        
        var cx = x3 - x1;
        var cy = y3 - y1;
        var t = (cx * dy - cy * dx) / b_dot_d_perp;
        
        if (t < 0 || t > 1) {
            return false
        }
        
        var u = (cx * by - cy * bx) / b_dot_d_perp;
        
        if (u < 0 || u > 1) {
            return false
        }
        
        return true
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



// MARK: CGPoint extensions for simple vector math

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