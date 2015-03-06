//
//  PPCanvas.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/6/15.
//
//

import UIKit

class PPCanvas: UIView{
    var strokes = [PPStroke]()
    var redoStrokes = [PPStroke]()
    var activeStroke: PPStroke?
    var activeStrokeSegmentsDrawn = 0
    var canvasThusFar: UIImage?
    var touchEvents = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Touch handling
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        // TODO: NOTE TO SELF: may need to hold finger down for fineline support
        // http://www.adonit.net/blog/archives/2015/01/05/ipad-air-2/
        
        TouchManager.GetTouchManager().addTouches(touches, knownTouches: event.touchesForView(self), view: self)
        if let touch = getActiveTouch(touches){
            addPointToActiveStroke(touch)
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        TouchManager.GetTouchManager().moveTouches(touches, knownTouches: event.touchesForView(self), view: self)
        if let touch = getActiveTouch(touches){
            self.touchEvents++
            addPointToActiveStroke(touch)
            
            // Only redraw the active stroke once every .05s or so
            if (!self.activeStroke!.isDot()){
                self.setNeedsDisplay()
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        TouchManager.GetTouchManager().moveTouches(touches, knownTouches: event.touchesForView(self), view: self)
        
        if let touch = getActiveTouch(touches){
            addPointToActiveStroke(touch)
            strokes.append(self.activeStroke!)
            self.activeStroke = nil
            self.setNeedsDisplay()
        }
            
        TouchManager.GetTouchManager().removeTouches(touches, knownTouches: event.touchesForView(self), view: self)
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        TouchManager.GetTouchManager().removeTouches(touches, knownTouches: event.touchesForView(self), view: self)
    }

    
    // MARK: Touch tracking helper functions

    // Get the active drawing point, with handling for whether a stylus is connected or not
    func getActiveTouch(touches: NSSet) -> UITouch?{
        var touch = touches.anyObject() as UITouch
        if (WacomManager.getManager().isADeviceSelected()){
            var stylusTouches = TouchManager.GetTouchManager().getTouches()
            if (stylusTouches == nil || stylusTouches.first == nil){
                // no stylus touches; nothing to draw
                return nil
            } else {
                touch = stylusTouches.first! as UITouch
            }
        }
        return touch
    }
    
    // Initialize the active stroke if needed, then add another point to the stroke
    // Includes handling for stylus pressure
    func addPointToActiveStroke(touch: UITouch){
        // Start a stroke if there's not an ongoing stroke already
        if (self.activeStroke == nil){
            self.activeStroke = PPStroke(color: PPToolConfiguration.sharedInstance.color, width: PPToolConfiguration.sharedInstance.width)
            self.activeStrokeSegmentsDrawn = 0
        }
        
        // Report pressure if using a stylus
        if let p = PPToolConfiguration.sharedInstance.pressure {
            self.activeStroke!.addPoint(touch, withPressure: p, inView:self)
        } else {
            self.activeStroke!.addPoint(touch, inView:self)
        }
    }

    
    // MARK: Toolbar actions
    
    func clear(){
        self.canvasThusFar = nil
        self.strokes = [PPStroke]()
        self.setNeedsDisplay()
    }
    
    func undo(){
        if self.strokes.count > 0{
            self.redoStrokes.append(self.strokes.removeLast())
            self.setNeedsDisplay()
        }
    }
    
    func redo(){
        if self.redoStrokes.count > 0{
            self.strokes.append(self.redoStrokes.removeLast())
            self.setNeedsDisplay()
        }
    }
    
    
    // MARK: Rendering
    
    func drawStroke(stroke: PPStroke, quickly:Bool){
        if CGColorGetAlpha(stroke.color.CGColor) == 0 {
            // Eraser mode
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear)
        } else {
            // Pencil mode
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal)
        }
        
        stroke.color.setFill()
        if (quickly){
            var paths = stroke.asBezierPaths()
            for var i = max(0, self.activeStrokeSegmentsDrawn - 1); i < paths.count; i++ {
                paths[i].fill()
            }
            self.activeStrokeSegmentsDrawn = paths.count
        } else {
            for path in stroke.asBezierPaths(){
                path.fill()
            }
        }
    }
    
    override func drawRect(rect: CGRect) {
        // We're gonna save everything to a cached UIImage
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        
        if let stroke = activeStroke{
            // Draw just the latest line segment
            if let cachedImage = canvasThusFar {
                cachedImage.drawInRect(rect)
            } else {
                UIColor.whiteColor().setFill()
                UIBezierPath(rect: self.bounds).fill()
            }
            
            drawStroke(stroke, quickly: true)
        } else {
            // Redraw everything from scratch
            UIColor.whiteColor().setFill()
            UIBezierPath(rect: self.bounds).fill()
            for stroke in strokes{
                drawStroke(stroke, quickly: false)
            }
        }
        
        // Save results to a cached image
        canvasThusFar = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Draw result to screen
        canvasThusFar!.drawInRect(rect)
    }
    
    func asImage() -> UIImage{
        if canvasThusFar == nil{
            return UIImage()
        } else {
            return canvasThusFar!
        }
    }
}