//
//  CanvasScrollView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/5/15.
//
//

import UIKit
import Toast_Swift

class CanvasScrollView: UIScrollView, UIScrollViewDelegate{
    var layers = [Canvas]()
    var currentLayer: Canvas! {
        didSet {
            didSetCurrentLayer()
        }
    }
    var diagnosticsView: UILabel?
    static let FPS_DISPLAY_RATE: Double = 0     // How often should we show the on-screen FPS indicator?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.backgroundColor = UIColor.whiteColor()
        
        // Initialize our content view layers, which will handle actual drawing
        self.layers = [Canvas(frame: self.bounds), Canvas(frame: self.bounds)]
        for layer in layers.reverse() { // Reversed so that the "first" layer ends up on top
            addSubview(layer)
        }
        
        // Set current active layer
        // Note that Swift does not call didSet when setting attrs in init() :|
        self.currentLayer = self.layers.first
        didSetCurrentLayer()
        
        // Initialize a view for showing diagnostics
        if CanvasScrollView.FPS_DISPLAY_RATE > 0 {
            self.diagnosticsView = UILabel(frame: CGRectMake(10, 10, 100, 18))
            self.diagnosticsView!.textAlignment = NSTextAlignment.Left
            self.diagnosticsView!.numberOfLines = 0
            self.diagnosticsView!.text = "FPS: 0.0"
            addSubview(self.diagnosticsView!)
            NSTimer.scheduledTimerWithTimeInterval(1.0 / CanvasScrollView.FPS_DISPLAY_RATE,
                target: self,
                selector: #selector(CanvasScrollView.updateDiagnostics),
                userInfo: nil,
                repeats: true)
        }
        
        // Only scroll with four fingers, plz
        self.panGestureRecognizer.minimumNumberOfTouches = 4
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CanvasScrollView.clear), name: "ResizeCanvas", object: nil)
    }
    
    func didSetCurrentLayer(){
        // Note that Swift does not call didSet when setting attrs in init()
        // Thus we need to manually call this method after initializing our layers
        for layer in layers {
            layer.userInteractionEnabled = false
        }
        currentLayer.userInteractionEnabled = true
        
        JotStylusManager.sharedInstance().jotStrokeDelegate = currentLayer
    }
    
    func updateDiagnostics(){
        self.diagnosticsView?.text = "FPS: \(Double(currentLayer.touchEvents) * CanvasScrollView.FPS_DISPLAY_RATE)"
        currentLayer.touchEvents = 0
    }
    
    override func layoutSubviews() {
        if (AppConfig.sharedInstance.widerCanvas){
            // Set content size to 2x screen width, 1x screen height
            self.contentSize = CGSize(width:CGRectGetWidth(frame) * 2, height: CGRectGetHeight(frame))
        } else {
            // Set content size to 1x screen width, 1x screen height
            self.contentSize = CGSize(width:CGRectGetWidth(frame), height: CGRectGetHeight(frame))
        }
        
        for layer in layers {
            layer.frame.size = self.contentSize
        }
    }
    
    func clear(){
        currentLayer.clear()
        self.layoutSubviews()
    }
    
    func undo(){
        currentLayer.undo()
    }
    
    func redo(){
        currentLayer.redo()
    }
    
    func switchLayers(){
        if currentLayer == layers.first {
            currentLayer = layers.last
        } else {
            currentLayer = layers.first
        }
        
        self.makeToast("Switched layers", duration: 1.0, position: .Bottom)
    }
    
    
    // MARK: Image export functions
    
    func asImage() -> UIImage{
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        drawViewHierarchyInRect(self.bounds, afterScreenUpdates:true)
        let viewAsImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return viewAsImage
    }
    
    func asNSData() -> NSData{
        return UIImagePNGRepresentation(self.asImage())!
    }
}
