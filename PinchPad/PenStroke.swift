//
//  PenStroke.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/19/16.
//
//

class PenStroke: VariableStroke {
    static let THINNING_DISTANCE: Double = 2
    
    override func getSimulatedPressure(newPoint: CGPoint) -> CGFloat{
        let pointsCount = points.count

        // If we don't have enough data (e.g. we're at the first point), return a reasonable default
        if (pointsCount == 0){
            return 1.0
        }
        
        let lastPoint = points[points.count-1]
        let diff = (newPoint - lastPoint.location).length()
        
        if (diff <= PenStroke.THINNING_DISTANCE){
            return 1.0
        }
        
        var fakePressure = max(CGFloat(0.3), CGFloat(1.0 - log(diff-PenStroke.THINNING_DISTANCE)/log(16)))
        
        // Smooth out pressure using previous points, to prevent abrupt pressure changes
        let previousPointsToSmoothAgainstCount = min(2, points.count)
        for index in 1...previousPointsToSmoothAgainstCount{
            fakePressure += points[pointsCount-index].pressure
        }
        return fakePressure / (CGFloat(previousPointsToSmoothAgainstCount)+1.0)
    }
}
