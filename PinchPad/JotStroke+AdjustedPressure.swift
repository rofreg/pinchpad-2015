//
//  JotStroke+AdjustedPressure.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/15/16.
//
//

extension JotStroke {
    var adjustedPressure: CGFloat {
        get { return clamp(pressure * 1.5, lower: 0.2, upper: 1.0) }
    }
}
