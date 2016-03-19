//
//  CanvasScrollView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/5/15.
//
//

import UIKit

class CanvasScrollView: UIScrollView, UIScrollViewDelegate{
    var contentView: Canvas!
    var diagnosticsView: UILabel?
    static let FPS_DISPLAY_RATE: Double = 0     // How often should we show the on-screen FPS indicator?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.backgroundColor = UIColor.whiteColor()
        
        // Initialize our content view, which will handle actual drawing
        self.contentView = Canvas(frame: self.bounds)
        addSubview(self.contentView)
        
        // Initialize a view for showing diagnostics
        if CanvasScrollView.FPS_DISPLAY_RATE > 0 {
            self.diagnosticsView = UILabel(frame: CGRectMake(10, 10, 100, 18))
            self.diagnosticsView!.textAlignment = NSTextAlignment.Left
            self.diagnosticsView!.numberOfLines = 0
            self.diagnosticsView!.text = "FPS: 0.0"
            addSubview(self.diagnosticsView!)
            NSTimer.scheduledTimerWithTimeInterval(1.0 / CanvasScrollView.FPS_DISPLAY_RATE,
                target: self,
                selector: "updateDiagnostics",
                userInfo: nil,
                repeats: true)
        }
        
        // Only scroll with two fingers, plz
        self.panGestureRecognizer.minimumNumberOfTouches = 2
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clear"), name: "ResizeCanvas", object: nil)
    }
    
    func updateDiagnostics(){
        self.diagnosticsView?.text = "FPS: \(Double(self.contentView.touchEvents) * CanvasScrollView.FPS_DISPLAY_RATE)"
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
