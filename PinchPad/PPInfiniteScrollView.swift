//
//  PPInfiniteScrollView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/5/15.
//
//

import UIKit

class PPInfiniteScrollView: UIScrollView, UIScrollViewDelegate{
    var contentView: PPCanvas!
    var diagnosticsView: UILabel!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.backgroundColor = UIColor.whiteColor()
        
        // Initialize our content view, which will handle actual drawing
        self.contentView = PPCanvas(frame: self.bounds)
        addSubview(self.contentView)
        
        // Initialize a view for showing diagnostics
        self.diagnosticsView = UILabel(frame: CGRectMake(10, 10, 100, 100))
        self.diagnosticsView.textAlignment = NSTextAlignment.Left
        self.diagnosticsView.numberOfLines = 0
        self.diagnosticsView.text = "Testing"
        addSubview(self.diagnosticsView)
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "updateDiagnostics", userInfo: nil, repeats: true)
        
        // Only scroll with two fingers, plz
        if let recognizers = self.gestureRecognizers{
            for recognizer in recognizers{
                if (recognizer.isKindOfClass(UIPanGestureRecognizer)) {
                    (recognizer as UIPanGestureRecognizer).minimumNumberOfTouches = 2
                }
            }
        }
    }
    
    func updateDiagnostics(){
        self.diagnosticsView.text = "\(self.contentView.touchEvents * 5)"
        self.contentView.touchEvents = 0
    }
    
    override func layoutSubviews() {
        // Set content size to 2x screen width, 1x screen height
        self.contentSize = CGSize(width:CGRectGetWidth(frame) * 2, height: CGRectGetHeight(frame))
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
    
    func clear(){
        self.contentView.clear()
    }
    
    func undo(){
        self.contentView.undo()
    }
    
    func redo(){
        self.contentView.redo()
    }
}
