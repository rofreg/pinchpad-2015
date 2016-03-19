//
//  BrushStroke.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/19/16.
//
//

class BrushStroke: VariableStroke {
    static let BASELINE_SPEED: Double = 200
    
    override func getSimulatedPressure(newPoint: CGPoint) -> CGFloat{
        let pointsCount = points.count
        
        // If we don't have enough data (e.g. we're at the first point), return a reasonable default
        if (pointsCount == 0){
            return 0.5
        }
        
        let lastPoint = points[points.count-1]
        let pxPerSec = (newPoint - lastPoint.location).length() / (NSDate.timeIntervalSinceReferenceDate() - lastPoint.time)
        var fakePressure = clamp(CGFloat(pxPerSec - BrushStroke.BASELINE_SPEED) / 8.0, lower: 0.5, upper: 1.0)
        
        // Smooth out pressure using previous points, to prevent abrupt pressure changes
        let previousPointsToSmoothAgainstCount = min(2, points.count)
        for index in 1...previousPointsToSmoothAgainstCount{
            fakePressure += points[pointsCount-index].pressure
        }
        return fakePressure / (CGFloat(previousPointsToSmoothAgainstCount)+1.0)
    }
}