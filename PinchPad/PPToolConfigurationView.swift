//
//  PPToolConfigurationView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/8/15.
//
//

import UIKit

class PPToolConfigurationViewController: UIViewController{
    @IBOutlet var toolPicker: UISegmentedControl!
    @IBOutlet var slider: UISlider!     // TODO: segmented steps on the slider
    @IBOutlet var previewWindow: PPCanvas!
    
    override func viewDidLoad() {
        updatePreview()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePreview", name: "PPToolConfigurationChanged", object: nil)
    }
    
    
    // Tool configuration IBActions
    
    @IBAction func toolChanged(sender: UISegmentedControl){
        switch (sender.selectedSegmentIndex){
            case 0:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Brush
                PPToolConfiguration.sharedInstance.color = UIColor.blackColor()
                break;
            case 1:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Marker
                PPToolConfiguration.sharedInstance.color = UIColor.redColor()
                break;
            case 2:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Eraser
                PPToolConfiguration.sharedInstance.color = UIColor.blueColor()
                break;
            default:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Brush
                break;
        }
    }
    
    @IBAction func widthChanged(sender: UISlider){
        var roundedValue = Int(round(sender.value))
        sender.setValue(Float(roundedValue), animated: false)
        
        let realSize = [0.0, 1.0, 3.0, 5.0, 10.0, 30.0, 60.0]
        let toolSize = realSize[roundedValue]
        PPToolConfiguration.sharedInstance.width = CGFloat(toolSize)
    }
    
    
    // MARK: Stroke preview logic
    
    func updatePreview(){
        previewWindow.strokes = [previewStroke()]
        previewWindow.setNeedsDisplay()
        
        // Update the tool picker if the tool choice changed
        let tool = PPToolConfiguration.sharedInstance.tool
        if (tool == .Brush && toolPicker.selectedSegmentIndex != 0){
            toolPicker.selectedSegmentIndex = 0
        } else if (tool == .Marker && toolPicker.selectedSegmentIndex != 1){
            toolPicker.selectedSegmentIndex = 1
        } else if (tool == .Eraser && toolPicker.selectedSegmentIndex != 2){
            toolPicker.selectedSegmentIndex = 2
        }
    }
    
    func previewStroke() -> PPStroke{
        let PPTCsI = PPToolConfiguration.sharedInstance
        var stroke = PPStroke(tool: PPTCsI.tool, width: PPTCsI.width, color: PPTCsI.color)
        
        // Construct a sample squiggle
        var windowSize = previewWindow!.frame.size.height
        stroke.addPoint(CGPointMake(windowSize * 0.1, windowSize * 0.9))
        stroke.addPoint(CGPointMake(windowSize * 0.25, windowSize * 0.8))
        stroke.addPoint(CGPointMake(windowSize * 0.4, windowSize * 0.7))
        stroke.addPoint(CGPointMake(windowSize * 0.55, windowSize * 0.6))
        stroke.addPoint(CGPointMake(windowSize * 0.5, windowSize * 0.5))
        stroke.addPoint(CGPointMake(windowSize * 0.45, windowSize * 0.4))
        stroke.addPoint(CGPointMake(windowSize * 0.6, windowSize * 0.3))
        stroke.addPoint(CGPointMake(windowSize * 0.75, windowSize * 0.2))
        stroke.addPoint(CGPointMake(windowSize * 0.9, windowSize * 0.1))
        
        return stroke
    }
}