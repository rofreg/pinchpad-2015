//
//  PPInfiniteScrollView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/5/15.
//
//

import UIKit

class PPInfiniteScrollView: UIScrollView, UIScrollViewDelegate{
    var contentView: UIView!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.backgroundColor = UIColor.whiteColor()
        
        // Initialize our content view, which will handle actual drawing
        self.contentView = PPCanvas(frame: self.bounds)
        addSubview(self.contentView)
        
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
        self.contentSize = CGSize(width:CGRectGetWidth(frame) * 2, height: CGRectGetHeight(frame) * 2)
        self.contentView.frame.size = self.contentSize;
//        self.contentView.frame.size.width -= 50
//        self.contentView.frame.size.height -= 50
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        //zoomtorect
        println(self.zoomScale)
        println(self.contentView.frame.size)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Scale our drawing view up and down
        if scrollView.contentOffset.x > 999999{
            println("TOO BIG")
        }
        
        
        var leftMargin = (self.frame.size.width - self.contentView.frame.size.width)*0.5;
        var topMargin = (self.frame.size.height - self.contentView.frame.size.height)*0.5;
        self.contentInset = UIEdgeInsetsMake(max(0, topMargin), max(0, leftMargin), 0, 0);
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return nil
//        return self.contentView
    }
}
