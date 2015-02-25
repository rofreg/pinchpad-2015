//
//  PPToolConfigurationView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/8/15.
//
//

import UIKit

class PPToolConfigurationViewController: UIViewController{
    var delegate: PPToolConfigurationViewControllerDelegate?
    @IBOutlet var slider: UISlider?
    @IBOutlet var previewWindow: PPCanvas?
    
    override func viewDidLoad() {
        updatePreview()
    }
    
    @IBAction func widthChanged(sender: UISlider){
        if let d = delegate{
            d.widthChanged(sender.value)
            updatePreview()
        }
    }
    
    // MARK: Stroke preview logic
    
    func updatePreview(){
        if let pW = previewWindow{
            pW.strokes = [previewStroke()]
            pW.setNeedsDisplay()
        }
    }
    
    func previewStroke() -> PPStroke{
        var stroke = PPStroke(color: UIColor.blackColor(), width: CGFloat(slider!.value))
        var windowSize = previewWindow!.frame.size.height
        stroke.addPoint(CGPointMake(windowSize * 0.1, windowSize * 0.9), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.25, windowSize * 0.8), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.4, windowSize * 0.7), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.55, windowSize * 0.6), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.5, windowSize * 0.5), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.45, windowSize * 0.4), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.6, windowSize * 0.3), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.75, windowSize * 0.2), inView: previewWindow!)
        stroke.addPoint(CGPointMake(windowSize * 0.9, windowSize * 0.1), inView: previewWindow!)
        return stroke
    }
}


protocol PPToolConfigurationViewControllerDelegate {
    func widthChanged(value: Float)
}