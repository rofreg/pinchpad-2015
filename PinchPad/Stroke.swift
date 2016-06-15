//
//  Stroke.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/19/16.
//
//

import UIKit

class Stroke{
    let color: UIColor
    let width: CGFloat
    var points = [StrokePoint]()
    var minimumPointDistance: Double {
        get {
            // May be overridden by subclasses (untested)
            return ToolConfig.sharedInstance.isStylusConnected ? 0.1 : 3
        }
    }
    
    required init(width: CGFloat!, color: UIColor!){
        self.width = width
        self.color = color
    }
    
    
    // MARK: Point management logic
    
    func addPoint(touch: UITouch, inView view: UIView, withPressure pressure: CGFloat? = nil){
        let location = touch.locationInView(view)
        self.addPoint(location, withPressure: pressure)
    }
    
    func addPoint(location: CGPoint, withPressure pressure: CGFloat? = nil){
        // Do not add this point if it's too close to the last point
        if let lastPoint = self.points.last where (lastPoint.location - location).length() < minimumPointDistance {
            // Handle pressure changes (i.e. I stayed still, but pressed down harder)
            if let currentPressure = pressure where currentPressure > lastPoint.pressure {
                self.points.removeLast()
                self.points.append(StrokePoint(location: lastPoint.location, pressure: currentPressure))
            }
            return
        }
        
        self.points.append(StrokePoint(location: location, pressure: pressure ?? getSimulatedPressure(location)))
    }
    
    func getSimulatedPressure(newPoint: CGPoint) -> CGFloat{
        return 1.0
    }
    
    
    // MARK: Rendering logic
    // To draw custom stroke styles, override this in a subclass
    
    func drawInView(view: UIView, quickly: Bool){
        self.color.setFill()
        self.color.setStroke()
        self.asBezierPath(quickly).stroke()
    }
    
    // Is this stroke just a dot?
    func isDot() -> Bool{
        if points.count <= 2{
            return true
        } else if points.count <= 3 && (points.first!.location - points.last!.location).length() < 25{
            // Count very quick taps as dots
            return true
        }
        
        return false
    }
    
    // This returns a single bezier path connecting all points, which can be stroke()'d
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
            return path
        }
        
        path.moveToPoint(self.points[0].location)
        path.addLineToPoint((self.points[0].location + self.points[1].location) * 0.5)
        
        // Draw quadratic curves between each midpoint
        for cpi in 1 ..< self.points.count - 1 {
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
}


// MARK: StrokePoint class

class StrokePoint: NSObject{
    let location: CGPoint
    let pressure: CGFloat
    let time: NSTimeInterval
    
    init(location: CGPoint!, pressure: CGFloat!){
        self.location = location
        self.pressure = pressure
        self.time = NSDate.timeIntervalSinceReferenceDate()
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

func /(left:CGPoint, scalar:Double) -> CGPoint{
    return left * (1/scalar)
}