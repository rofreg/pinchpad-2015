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
    var cachedFinalPoints = [PPPoint]()
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
        let location = touch.locationInView(inView)
        self.addPoint(location, withPressure: pressure)
    }
    
    func addPoint(touch: UITouch, inView: UIView){
        let location = touch.locationInView(inView)
        self.addPoint(location)
    }
    
    func addPoint(location: CGPoint){
        // Fake pressure, simulated from velocity between points
        var p: CGFloat
        let pointsCount = points.count
        if (pointsCount == 0){
            p = 0.5
        } else {
            let lastPoint = points[points.count-1]
            let diff = (location - lastPoint.location).length()
            p = max(0.5, min(1.0, CGFloat(diff - 5) / 8.0))
            
            // Smooth out pressure using previous points, to prevent abrupt pressure changes
            let previousPointsToSmoothAgainstCount = min(2, points.count)
            for index in 1...previousPointsToSmoothAgainstCount{
                p += points[pointsCount-index].pressure
            }
            p = p / (CGFloat(previousPointsToSmoothAgainstCount)+1.0)
        }
        
        self.addPoint(location, withPressure: p)
    }
    
    // TODO: thin out number of points around slow tight curves?
    func addPoint(location: CGPoint, withPressure pressure: CGFloat){
        // Do not add this point if it's too close to the last point
        if let lastPoint = self.points.last where (lastPoint.location - location).length() < 3 {
            // TODO: handle pressure changes (i.e. I stayed still, but pressed down harder)
            return;
        }
        
        self.points.append(PPPoint(location: location, pressure: pressure))
    }
    
    
    // MARK: Rendering logic
    
    func drawInView(view: UIView, quickly: Bool){
        self.color.setFill()
        self.color.setStroke()
        
        if (self.tool == PPToolType.Brush){
            // We need to do special handling for performance for the brush
            var paths = self.asBezierPaths(quickly)
            if (quickly){
                // Draw all but the very last segment (which is a dot, and might change later)
                for (var i = max(0, self.strokeSegmentsDrawn - 1); i < max(0, paths.count - 1); i++) {
                    paths[i].fill()
                    paths[i].stroke()
                }
                self.strokeSegmentsDrawn = paths.count - 1
            } else {
                for path in paths{
                    path.fill()
                    path.stroke()
                }
            }
        } else if (self.tool == PPToolType.Marker) {
            // For the marker, just draw the line
            self.asBezierPath(quickly).stroke()
        } else if (self.tool == PPToolType.Eraser) {
            // For the eraser, just draw the line
            UIColor.whiteColor().setStroke()
            self.asBezierPath(quickly).stroke()
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
        let path = UIBezierPath()
        path.lineWidth = self.width
        path.lineCapStyle = CGLineCap.Round
        path.lineJoinStyle = CGLineJoin.Round
        
        // Handle dot case
        if (self.isDot()){
            // Draw a dot at the starting point
            // Line stroke thickness will take care of the actual "radius"
            path.addArcWithCenter(points.first!.location, radius: 0.01, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
            return path;
        }
        
        path.moveToPoint(self.points[0].location)
        path.addLineToPoint((self.points[0].location + self.points[1].location) * 0.5)
        
        // Generate any new segments with Catmull-Rom interpolation and connect them
        for (var cpi = 1; cpi < self.points.count - 1; cpi++) {
            let currentPoint = self.points[cpi].location
            let nextPoint = self.points[cpi+1].location
            let nextMidpoint = (currentPoint + nextPoint) * 0.5
            path.addQuadCurveToPoint(nextMidpoint, controlPoint: currentPoint)
        }
        
        if (!quickly){
            path.addLineToPoint(self.points.last!.location)
        }
        
        return path
    }
    
    // TODO
    // http://www.merowing.info/2012/04/drawing-smooth-lines-with-cocos2d-ios-inspired-by-paper/#.VPnbmGRViko
    // https://github.com/krzysztofzablocki/smooth-drawing
    // ^ suggests alternatives to catmull-rom interpolation ^
    // https://developer.apple.com/library/mac/documentation/graphicsimaging/Reference/CGPath/Reference/reference.html#//apple_ref/c/func/CGPathCreateCopyByStrokingPath
    // http://stackoverflow.com/questions/16547572/generate-a-cgpath-from-another-paths-line-width-outline
    // http://stackoverflow.com/questions/24463832/ios-how-to-draw-a-stroke-with-an-outline
    // http://code.tutsplus.com/tutorials/ios-sdk-advanced-freehand-drawing-techniques--mobile-15602
    
    
    // TODO: handle jitter when ending stroke?
    // TODO: cache final points in progress
    func finalPoints(quickly: Bool = false) -> [PPPoint]{
        if (self.isDot()){
            self.cachedFinalPoints = self.points
            return self.points
        } else {
            var smoothedPoints = [PPPoint]()
            let minSegmentsBetweenTwoPoints = (quickly ? 2 : 16)
            smoothedPoints.reserveCapacity(points.count * minSegmentsBetweenTwoPoints)
            
            for (var i = 2; i < points.count; i++) {
                let p1 = points[i-2]
                let p2 = points[i-1]
                let p3 = points[i]
                
                let p12Midpoint = (p1.location + p2.location) * 0.5
                let p23Midpoint = (p2.location + p3.location) * 0.5
                
                let distance = (p12Midpoint - p23Midpoint).length()
                let segmentDistance = (quickly ? 10.0 : 4.0)
                let numberOfSegments = min(128, max(floor(distance / segmentDistance), Double(minSegmentsBetweenTwoPoints)))
//                println("distance: \(distance)")
//                println("segments: \(numberOfSegments)")
                
                
                var t = 0.0
                let step = 1.0 / numberOfSegments
                var lastLocation: CGPoint?
                for (var j = 0; j < Int(numberOfSegments); j++) {
                    var l = (p12Midpoint * pow(1-t, 2))
                    l = l + (p2.location * (2 * (1-t) * t))
                    l = l + (p23Midpoint * (t*t))
                    
                    // Don't add this point to the list if it's super-close to the last point
                    // (This prevents divide-by-zero errors in other places when two points are identical
                    if let lL = lastLocation where (lL - l).length() < 0.1 {
                        continue
                    } else {
                        lastLocation = l
                    }
                    
                    let p1p = Double(p1.pressure)
                    let p2p = Double(p2.pressure)
                    let p3p = Double(p3.pressure)
                    
                    var p = pow(1-t, 2) * ((p1p + p2p)/2.0)
                    p = p + p2p * (2 * (1-t) * t)
                    p = p + ((p2p + p3p)/2.0) * (t * t)
                    
                    let x : PPPoint = PPPoint(location: l, pressure: CGFloat(p))
                    smoothedPoints.append(x)
                    t += step
                }
            }

            self.cachedFinalPoints = smoothedPoints
            return smoothedPoints
        }
    }
    
    // This returns a series of POLYGONS that simulate pressure
    func asBezierPaths(quickly: Bool = false) -> [UIBezierPath]{
        if (quickly && cachedPointsCount == points.count) {
            // This stroke hasn't changed since the last time we rendered it
            return cachedBezierPaths
        } else if self.isDot(){
            // This is just a dot
            let dot = UIBezierPath()
            dot.addArcWithCenter(points.first!.location, radius: width * 0.5, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
            self.cachedBezierPaths = [dot]
        } else {
            // Let's calculate a fancy stroke!
            var finalPoints = self.finalPoints(quickly)
            self.cachedBezierPaths = []
            self.cachedBezierPaths.reserveCapacity(finalPoints.count + 5)
    
            // Generate two bounding paths to create stroke thickness
            // First point needs a bit of special handling
            var startPoints = pointsOnLineSegmentPerpendicularTo([finalPoints[1].location, finalPoints[0].location], length: width * finalPoints[1].pressure)
            var boundingPoints = [[startPoints[1], startPoints[0]]]
            
            // Now calculate all points in the middle of the path
            for (var fpi = 0; fpi < finalPoints.count - 1; fpi++) {
                let startPoint = finalPoints[fpi]
                let endPoint = finalPoints[fpi+1]
                let newPoints = pointsOnLineSegmentPerpendicularTo([startPoint.location, endPoint.location], length: endPoint.pressure * width)
                boundingPoints.append(newPoints)
            }
            
            // Make an initial path from the opening point, if we haven't already)
            if (self.cachedBezierPaths.count == 0){
                // Draw a dot at the starting location, to round the starting point off
                let path = UIBezierPath()
                path.addArcWithCenter(finalPoints.first!.location, radius: width * finalPoints[1].pressure, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
                self.cachedBezierPaths.append(path)
            }
            
            for (var bpi = 0; bpi < boundingPoints.count - 1; bpi++) {
                // Add our first line segment
                let path = UIBezierPath()
                path.moveToPoint(boundingPoints[bpi][0])
                path.addLineToPoint(boundingPoints[bpi+1][0])
                path.addLineToPoint(boundingPoints[bpi+1][1])
                path.addLineToPoint(boundingPoints[bpi][1])
                path.closePath()
                self.cachedBezierPaths.append(path)
            }
            
            // Draw a dot at the ending location, to round the ending point off
            let path = UIBezierPath()
            path.addArcWithCenter(finalPoints.last!.location, radius: width * finalPoints.last!.pressure, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
            self.cachedBezierPaths.append(path)
            
            // Set all polygons to have a thin line stroke (to handle the tiny rendering gaps between polygons)
            for path in self.cachedBezierPaths{
                path.lineWidth = 0.2
            }
            
            // TODO: also stroke center set of lines with minimum width?
        }
        
        self.cachedPointsCount = self.points.count
        return self.cachedBezierPaths
    }
    
    func pointsOnLineSegmentPerpendicularTo(lineSegment:[CGPoint], length: CGFloat) -> [CGPoint]{
        let directionVector = lineSegment.first! - lineSegment.last!
        var adjustment = CGPointMake(directionVector.y, -directionVector.x)
        adjustment = adjustment * (Double(length) / adjustment.length())
        
        return [lineSegment.last! + adjustment, lineSegment.last! + (adjustment*(-1))]
    }
}


// MARK: PPPoint class

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
