//
//  JotStroke+AdjustedPressure.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/15/16.
//
//

extension JotStroke {
    var adjustedPressure: CGFloat {
        get {
            return clamp(pressure*0.9 + 0.1, lower: 0.15, upper: 1.0)
        }
    }
}
