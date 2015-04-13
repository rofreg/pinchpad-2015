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
    var canvasThusFar: UIImage?
    var canvasAfterLastStroke: UIImage?
    var touchEvents = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Touch handling
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // TODO: NOTE TO SELF: may need to hold finger down for fineline support
        // http://www.adonit.net/blog/archives/2015/01/05/ipad-air-2/
        
        TouchManager.GetTouchManager().addTouches(touches, knownTouches: event.touchesForView(self), view: self)
        if let touch = getActiveTouch(touches){
            addPointToActiveStroke(touch)
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
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
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        TouchManager.GetTouchManager().moveTouches(touches, knownTouches: event.touchesForView(self), view: self)
        
        if let touch = getActiveTouch(touches){
            addPointToActiveStroke(touch)
            strokes.append(self.activeStroke!)
            self.activeStroke = nil
            self.setNeedsDisplay()
        }
            
        TouchManager.GetTouchManager().removeTouches(touches as Set<NSObject>, knownTouches: event.touchesForView(self), view: self)
    }
    
    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent!) {
        // This commonly gets called when a two-finger scroll occurs
        TouchManager.GetTouchManager().removeTouches(touches, knownTouches: event.touchesForView(self), view: self)
        self.activeStroke = nil
        self.setNeedsDisplay()
    }

    
    // MARK: Touch tracking helper functions

    // Get the active drawing point, with handling for whether a stylus is connected or not
    func getActiveTouch(touches: NSSet) -> UITouch?{
        var touch = touches.anyObject() as! UITouch
        if (WacomManager.getManager().isADeviceSelected()){
            var stylusTouches = TouchManager.GetTouchManager().getTouches()
            if (stylusTouches == nil || stylusTouches.first == nil){
                // no stylus touches; nothing to draw
                return nil
            } else {
                touch = stylusTouches.first as! UITouch
            }
        }
        return touch
    }
    
    // Initialize the active stroke if needed, then add another point to the stroke
    // Includes handling for stylus pressure
    func addPointToActiveStroke(touch: UITouch){
        // Start a stroke if there's not an ongoing stroke already
        if (self.activeStroke == nil){
            self.activeStroke = PPStroke(tool: PPToolConfiguration.sharedInstance.tool, width: PPToolConfiguration.sharedInstance.width, color: PPToolConfiguration.sharedInstance.color)
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
        self.canvasAfterLastStroke = nil
        self.strokes = [PPStroke]()
        self.setNeedsDisplay()
    }
    
    func undo(){
        if self.strokes.count > 0{
            self.redoStrokes.append(self.strokes.removeLast())
            canvasAfterLastStroke = nil     // Clear stored canvas
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
            
            stroke.drawInView(self, quickly: true)
        } else {
            // Redraw everything up to the last step
            UIColor.whiteColor().setFill()
            UIBezierPath(rect: self.bounds).fill()
            if let cachedImage = canvasAfterLastStroke {
                cachedImage.drawInRect(rect)
                
                // Draw the most recent stroke in full
                if let stroke = strokes.last {
                    stroke.drawInView(self, quickly: false)
                }
            } else {
                // We have no cached image, so redraw all strokes from scratch
                for stroke in strokes{
                    stroke.drawInView(self, quickly: false)
                }
            }
        }
        
        // Save results to a cached image
        canvasThusFar = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // If we're between strokes, save the canvas thus far
        if (activeStroke == nil){
            canvasAfterLastStroke = canvasThusFar
        }
        
        // Draw result to screen
        // TODO: this is slow. use a second view as an on-screen buffer?
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