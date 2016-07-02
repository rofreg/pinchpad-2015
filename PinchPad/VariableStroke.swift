//
//  VariableStroke.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/19/16.
//
//

class VariableStroke: Stroke {
    var cachedFinalPoints = [StrokePoint]()
    var cachedBezierPaths = [UIBezierPath]()
    var cachedPointsCount = 0
    var strokeSegmentsDrawn = 0
    
    
    override func drawInView(view: UIView, quickly: Bool){
        self.color.setFill()
        self.color.setStroke()
        let paths = self.asBezierPaths(quickly)
        if (quickly){
            // Draw all but the very last segment (which is a dot, and might change later)
            for i in (max(0, self.strokeSegmentsDrawn - 1)..<max(0, paths.count - 1)){
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
    }
    
    func widthForPressure(pressure: CGFloat) -> CGFloat{
        return clamp(width * pressure, lower: width*0.15, upper: width)
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
            var startPoints = pointsOnLineSegmentPerpendicularTo([finalPoints[1].location, finalPoints[0].location], length: widthForPressure(finalPoints[1].pressure))
            var boundingPoints = [[startPoints[1], startPoints[0]]]
            
            // Now calculate all points in the middle of the path
            for fpi in 0 ..< finalPoints.count - 1 {
                let startPoint = finalPoints[fpi]
                let endPoint = finalPoints[fpi+1]
                let newPoints = pointsOnLineSegmentPerpendicularTo([startPoint.location, endPoint.location], length: endPoint.pressure * width)
                boundingPoints.append(newPoints)
            }
            
            // Make an initial path from the opening point, if we haven't already)
            if (self.cachedBezierPaths.count == 0){
                // Draw a dot at the starting location, to round the starting point off
                let path = UIBezierPath()
                path.addArcWithCenter(finalPoints.first!.location, radius: widthForPressure(finalPoints[1].pressure), startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
                self.cachedBezierPaths.append(path)
            }
            
            if (quickly){
                // If drawing quickly, break this stroke into many small UIBezierPaths,
                // so we can choose to draw only the latest segment
                
                for bpi in 0 ..< boundingPoints.count - 1 {
                    // Add our first line segment
                    let path = UIBezierPath()
                    path.moveToPoint(boundingPoints[bpi][0])
                    path.addLineToPoint(boundingPoints[bpi+1][0])
                    path.addLineToPoint(boundingPoints[bpi+1][1])
                    path.addLineToPoint(boundingPoints[bpi][1])
                    path.closePath()
                    self.cachedBezierPaths.append(path)
                }
            } else {
                // If drawing slowly, we're drawing the whole stroke
                // That means using one connected UIBezierPath will be more efficient
                // TODO: clean up the way this interferes with cachedBezierPaths?
                // If we tried to draw this stroke again with quickly=true, I suspect
                // we might get erroneous behavior in some cases
                
                let path = UIBezierPath()
                path.moveToPoint(boundingPoints[0][0])
                for bpi in 0 ..< boundingPoints.count - 1 {
                    path.addLineToPoint(boundingPoints[bpi+1][0])
                }
                path.addLineToPoint(boundingPoints[boundingPoints.count-1][1])
                for bpi in (0 ..< boundingPoints.count - 1).reverse() {
                    path.addLineToPoint(boundingPoints[bpi][1])
                }
                path.closePath()
                self.cachedBezierPaths.append(path)
            }
            
            // Draw a dot at the ending location, to round the ending point off
            let path = UIBezierPath()
            path.addArcWithCenter(finalPoints.last!.location, radius: widthForPressure(finalPoints.last!.pressure), startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
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
    
    // TODO: handle jitter when ending stroke?
    // TODO: cache final points in progress
    func finalPoints(quickly: Bool = false) -> [StrokePoint]{
        if (self.isDot()){
            self.cachedFinalPoints = self.points
            return self.points
        } else {
            var smoothedPoints = [StrokePoint]()
            let minSegmentsBetweenTwoPoints = (quickly ? 2 : 16)
            let maxSegmentsBetweenTwoPoints = 128
            smoothedPoints.reserveCapacity(points.count * minSegmentsBetweenTwoPoints)
            
            for i in 2 ..< points.count {
                let p1 = points[i-2]
                let p2 = points[i-1]
                let p3 = points[i]
                
                let p12Midpoint = (p1.location + p2.location) * 0.5
                let p23Midpoint = (p2.location + p3.location) * 0.5
                
                let distance = (p12Midpoint - p23Midpoint).length()
                let segmentDistance = (quickly ? 10.0 : 4.0)
                let numberOfSegments = clamp(floor(distance / segmentDistance),
                    lower: Double(minSegmentsBetweenTwoPoints),
                    upper: Double(maxSegmentsBetweenTwoPoints))
                //                println("distance: \(distance)")
                //                println("segments: \(numberOfSegments)")
                
                var t = 0.0
                let step = 1.0 / numberOfSegments
                var lastLocation: CGPoint?
                for _ in 0 ..< Int(numberOfSegments) {
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
                    
                    let x : StrokePoint = StrokePoint(location: l, pressure: CGFloat(p))
                    smoothedPoints.append(x)
                    t += step
                }
            }
            
            self.cachedFinalPoints = smoothedPoints
            return smoothedPoints
        }
    }
    
    func pointsOnLineSegmentPerpendicularTo(lineSegment:[CGPoint], length: CGFloat) -> [CGPoint]{
        let directionVector = lineSegment.first! - lineSegment.last!
        var adjustment = CGPointMake(directionVector.y, -directionVector.x)
        adjustment = adjustment * (Double(length) / adjustment.length())
        
        return [lineSegment.last! + adjustment, lineSegment.last! + (adjustment*(-1))]
    }
}


// MARK: Add simple clamp function

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}
