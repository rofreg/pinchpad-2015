//
//  Canvas.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/6/15.
//
//

import UIKit

class Canvas: UIView {
    var strokes = [Stroke]()
    var redoStrokes = [Stroke]()
    var activeStroke: Stroke?
    var canvasThusFar: UIImage?
    var canvasAfterLastStroke: UIImage?
    var touchEvents = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        JotStylusManager.sharedInstance().jotStrokeDelegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Stroke handling
    
    func strokeBegan(atPoint point: CGPoint, withPressure pressure: CGFloat? = nil){
        addPointToActiveStroke(point, pressure: pressure)
    }
    
    func strokeMoved(toPoint point: CGPoint, withPressure pressure: CGFloat? = nil) {
        self.touchEvents += 1
        addPointToActiveStroke(point, pressure: pressure)
        
        // Only redraw the active stroke once every .05s or so
        if (!self.activeStroke!.isDot()){
            self.setNeedsDisplay()
        }
    }
    
    func strokeEnded(atPoint point: CGPoint, withPressure pressure: CGFloat? = nil){
        addPointToActiveStroke(point, pressure: pressure)
        strokes.append(self.activeStroke!)
        self.activeStroke = nil
        self.setNeedsDisplay()
    }
    
    func strokeCancelled(){
        self.activeStroke = nil
        self.setNeedsDisplay()
    }
    
    
    // MARK: Raw touch event handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (ToolConfig.sharedInstance.isStylusConnected) { return }
        
        if let touch = getActiveTouches(touches).first {
            strokeBegan(atPoint: touch.locationInView(self))
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (ToolConfig.sharedInstance.isStylusConnected) { return }
        
        if let touch = getActiveTouches(touches).first {
            strokeMoved(toPoint: touch.locationInView(self))
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (ToolConfig.sharedInstance.isStylusConnected) { return }
        
        if let touch = getActiveTouches(touches).first {
            strokeEnded(atPoint: touch.locationInView(self))
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if (ToolConfig.sharedInstance.isStylusConnected) { return }
        
        // This commonly gets called when a multi-finger scroll occurs
        strokeCancelled()
    }

    
    // MARK: Touch tracking helper functions

    // Get the active drawing point, with handling for whether a stylus is connected or not
    func getActiveTouches(touches: NSSet, withEvent event: UIEvent? = nil) -> [UITouch]{
        let touch = touches.anyObject() as! UITouch
        
        if let coalescedTouches = event?.coalescedTouchesForTouch(touch) {
            return coalescedTouches
        } else {
            return [touch]
        }
    }
    
    // Initialize the active stroke if needed, then add another point to the stroke
    // Includes handling for stylus pressure
    func addPointToActiveStroke(point: CGPoint, pressure: CGFloat? = nil){
        // Start a stroke if there's not an ongoing stroke already
        if (self.activeStroke == nil){
            self.activeStroke = ToolConfig.sharedInstance.tool.toStrokeType()
                .init(width: ToolConfig.sharedInstance.width,
                    color: ToolConfig.sharedInstance.color)
        }
        
        // Add point, with pressure data if available
        self.activeStroke!.addPoint(point, withPressure: pressure)
    }

    
    // MARK: Toolbar actions
    
    func clear(){
        self.canvasThusFar = nil
        self.canvasAfterLastStroke = nil
        self.strokes = [Stroke]()
        self.redoStrokes = [Stroke]()
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
    
    func asNSData() -> NSData{
        if canvasThusFar == nil{
            return NSData()
        } else{
            return UIImagePNGRepresentation(canvasThusFar!)!
        }
    }
    
    func asImage() -> UIImage{
        if canvasThusFar == nil{
            return UIImage()
        } else {
            return canvasThusFar!
        }
    }
}

extension Canvas : JotStrokeDelegate {
    // MARK: Adonit event handling handling
    func jotStylusStrokeBegan(stylusStroke: JotStroke) {
        let location = stylusStroke.locationInView(self)
        strokeBegan(atPoint: location, withPressure: stylusStroke.adjustedPressure)
    }
    
    func jotStylusStrokeMoved(stylusStroke: JotStroke) {
        let location = stylusStroke.locationInView(self)
        strokeMoved(toPoint: location, withPressure: stylusStroke.adjustedPressure)
    }
    
    func jotStylusStrokeEnded(stylusStroke: JotStroke) {
        let location = stylusStroke.locationInView(self)
        strokeEnded(atPoint: location, withPressure: stylusStroke.adjustedPressure)
    }
    
    func jotStylusStrokeCancelled(stylusStroke: JotStroke) {
        strokeCancelled()
    }
    
    
    // MARK: Gesture handling
    
    func jotSuggestsToEnableGestures(){}
    func jotSuggestsToDisableGestures(){}
}