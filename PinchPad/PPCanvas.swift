//
//  PPCanvas.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/5/15.
//
//

import UIKit

class PPCanvas: UIScrollView{
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = UIColor.redColor()
        
        // Only scroll with two fingers, plz
        if let recognizers = self.gestureRecognizers{
            for recognizer in recognizers{
                if (recognizer.isKindOfClass(UIPanGestureRecognizer)) {
                    (recognizer as UIPanGestureRecognizer).minimumNumberOfTouches = 2
                }
            }
        }
    }
    
    override func layoutSubviews() {
        // Set content size to 2x screen width, 1x screen height
        self.contentSize = CGSize(width:CGRectGetWidth(frame) * 2, height: CGRectGetHeight(frame))
    }
}
