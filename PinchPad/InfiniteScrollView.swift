//
//  InfiniteScrollView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/5/15.
//
//

import UIKit

class InfiniteScrollView: UIScrollView, UIScrollViewDelegate{
    var contentView: Canvas!
    var diagnosticsView: UILabel?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.backgroundColor = UIColor.whiteColor()
        
        // Initialize our content view, which will handle actual drawing
        self.contentView = Canvas(frame: self.bounds)
        addSubview(self.contentView)
        
        // Initialize a view for showing diagnostics
        /*
        self.diagnosticsView = UILabel(frame: CGRectMake(10, 10, 100, 18))
        self.diagnosticsView!.textAlignment = NSTextAlignment.Left
        self.diagnosticsView!.numberOfLines = 0
        self.diagnosticsView!.text = "FPS: 0.0"
        addSubview(self.diagnosticsView!)
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "updateDiagnostics", userInfo: nil, repeats: true)
        */
        
        // Only scroll with two fingers, plz
        self.panGestureRecognizer.minimumNumberOfTouches = 2
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clear"), name: "ResizeCanvas", object: nil)
    }
    
    func updateDiagnostics(){
        self.diagnosticsView?.text = "FPS: \(Double(self.contentView.touchEvents) * 2.5)"
        self.contentView.touchEvents = 0
    }
    
    override func layoutSubviews() {
        if (AppConfig.sharedInstance.widerCanvas){
            // Set content size to 2x screen width, 1x screen height
            self.contentSize = CGSize(width:CGRectGetWidth(frame) * 2, height: CGRectGetHeight(frame))
        } else {
            // Set content size to 1x screen width, 1x screen height
            self.contentSize = CGSize(width:CGRectGetWidth(frame), height: CGRectGetHeight(frame))
        }
        
        self.contentView.frame.size = self.contentSize
    }
    
    func clear(){
        self.contentView.clear()
        self.layoutSubviews()
    }
    
    func undo(){
        self.contentView.undo()
    }
    
    func redo(){
        self.contentView.redo()
    }
}
