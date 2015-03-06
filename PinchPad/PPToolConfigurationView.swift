//
//  PPToolConfigurationView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/8/15.
//
//

import UIKit

class PPToolConfigurationViewController: UIViewController{
    @IBOutlet var slider: UISlider?     // TODO: segmented steps on the slider
    @IBOutlet var previewWindow: PPCanvas?
    
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
        PPToolConfiguration.sharedInstance.width = CGFloat(sender.value)
    }
    
    
    // MARK: Stroke preview logic
    
    func updatePreview(){
        if let pW = previewWindow{
            pW.strokes = [previewStroke()]
            pW.setNeedsDisplay()
        }
    }
    
    func previewStroke() -> PPStroke{
        let PPTCsI = PPToolConfiguration.sharedInstance
        var stroke = PPStroke(color: PPTCsI.color, width: PPTCsI.width)
        
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