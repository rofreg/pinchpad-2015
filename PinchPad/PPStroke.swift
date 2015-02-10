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
    var points = [PPPoint]()
    var cachedBezierPaths = [UIBezierPath]()
    var cachedPointsCount = 0
    
    init(color: UIColor!, width: CGFloat!){
        self.color = color
        self.width = width
    }
    
    // TODO: thin out number of points around slow tight curves?
    func addPoint(touch: UITouch, inView: UIView){
        var location = touch.locationInView(inView)
        
        var p: CGFloat
        if points.count == 0{
            p = 0.4
        } else {
            var lastPoint = points[points.count-1]
            var diff = (location - lastPoint.location).length()
            p = max(0.4, min(1.0, CGFloat(diff) / 30.0))
        }
        
        self.points.append(PPPoint(location: location, pressure: p))
    }
    
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
            var smoothedPressure = (points[0].pressure + points[1].pressure + 0)/3
            var startPoints = pointsOnLineSegmentPerpendicularTo([points[1].location, points[0].location], length: smoothedPressure * self.width)
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
                    boundingPoints.append(newPoints)
                } else {
                    boundingPoints.append([])
                }
            }
            
            // TODO: wide-tipped end of path
            // Now calculate our end points
            smoothedPressure = (points[points.count - 2].pressure + points[points.count - 1].pressure + 0)/3
            var endPoints = pointsOnLineSegmentPerpendicularTo([points[points.count - 2].location, points[points.count - 1].location], length: smoothedPressure * self.width)
            boundingPoints.append([endPoints[0], endPoints[1]])
            
            
            boundingPoints.append([points.last!.location, points.last!.location])
            
            // Make an initial path from the opening point, if we haven't already)
            if (self.cachedBezierPaths.count == 0){
                // TODO: draw a dot at the starting location, to round the starting point off
                //                var path = UIBezierPath()
                //                path.addArcWithCenter(points.first!.location, radius: width*0.5, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true)
                //                self.cachedBezierPaths.append(path)
                
                var path = UIBezierPath()
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
            
            // TODO: draw a dot at the ending location, to round the ending point off
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