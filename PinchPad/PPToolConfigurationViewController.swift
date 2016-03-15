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
    @IBOutlet var slider: UISlider!     // TODO: show segmented steps on the slider
    @IBOutlet var sliderBackground: UIView!
    @IBOutlet var previewWindow: PPCanvas!
    @IBOutlet var colorCollectionView: UICollectionView!
    
    let colors = [UIColor.blackColor(), UIColor(hex:"999999"), UIColor(hex:"dddddd"), UIColor(hex:"F2CA42"), UIColor(hex:"00C3A9"), UIColor(hex:"D45354"), UIColor(hex:"2FCAD8"), UIColor(hex:"663300"), UIColor(hex:"af7a56"), UIColor(hex:"ab7dbe"), UIColor(hex:"ff8960"), UIColor(hex:"6e99d4"), UIColor(hex:"4c996e"), UIColor(hex:"dc9bb1")]
    
    override func viewDidLoad() {
        updatePreview()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePreview", name: "PPToolConfigurationChanged", object: nil)
        slider.maximumTrackTintColor = UIColor(white: 0.6, alpha: 1.0)  // Manually setting color as a workaround for a bug?
    }
    
    override func viewDidAppear(animated: Bool) {
        updateSliderBackground()
    }
    
    func updateSliderBackground() {
        for view in sliderBackground.subviews{
            view.removeFromSuperview()
        }
        
        var fullWidth = CGRectGetWidth(sliderBackground.frame)
        let fullHeight = CGRectGetHeight(sliderBackground.frame)
        let adjustmentRadius: CGFloat = 28.0
        fullWidth -= adjustmentRadius
        
        for index in 0...5{
            let tickMark = UIView(frame: CGRectMake(CGFloat(index) * (fullWidth / 5.0) - 1 + adjustmentRadius/2.0, fullHeight * 1.0/4.0 + 0.5, 2, fullHeight * 1.0/2.0))
            
            if (index < Int(slider.value)){
                tickMark.backgroundColor = slider.minimumTrackTintColor
            } else {
                tickMark.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
            }
            
            sliderBackground.addSubview(tickMark)
        }
    }
    
    
    // Tool configuration IBActions
    
    @IBAction func toolChanged(sender: UISegmentedControl){
        switch (sender.selectedSegmentIndex){
            case 0:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Brush
                break;
            case 1:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Marker
                break;
            case 2:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Pen
                break;
            case 3:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Eraser
                break;
            default:
                PPToolConfiguration.sharedInstance.tool = PPToolType.Brush
                break;
        }
    }
    
    @IBAction func widthChanged(sender: UISlider){
        let roundedValue = Int(round(sender.value))
        sender.setValue(Float(roundedValue), animated: false)
        
        let realSize = [0.0, 1.0, 3.0, 5.0, 10.0, 30.0, 60.0]
        let toolSize = realSize[roundedValue]
        PPToolConfiguration.sharedInstance.width = CGFloat(toolSize)
        
        updateSliderBackground()
    }
    
    
    // MARK: Stroke preview logic
    
    func updatePreview(){
        previewWindow.clear()
        
        if (PPToolConfiguration.sharedInstance.tool == .Eraser){
            previewWindow.strokes = [previewStroke(.Marker, width: 100, color: UIColor.blackColor()), previewStroke()]
        } else {
            previewWindow.strokes = [previewStroke()]
        }
        
        previewWindow.setNeedsDisplay()
        
        // Update the tool picker if the tool choice changed
        let tool = PPToolConfiguration.sharedInstance.tool
        if (tool == .Brush && toolPicker.selectedSegmentIndex != 0){
            toolPicker.selectedSegmentIndex = 0
        } else if (tool == .Marker && toolPicker.selectedSegmentIndex != 1){
            toolPicker.selectedSegmentIndex = 1
        } else if (tool == .Pen && toolPicker.selectedSegmentIndex != 2){
            toolPicker.selectedSegmentIndex = 2
        } else if (tool == .Eraser && toolPicker.selectedSegmentIndex != 3){
            toolPicker.selectedSegmentIndex = 3
        }
        
        // Update the color picker if the color changed
        colorCollectionView.reloadData()
    }
    
    func previewStroke(tool: PPToolType? = nil, width: CGFloat? = nil, color: UIColor? = nil) -> PPStroke{
        let stroke: PPStroke
        if let tool = tool, width = width, color = color{
            stroke = PPStroke(tool: tool, width: width, color: color)
        } else {
            let PPTCsI = PPToolConfiguration.sharedInstance
            stroke = PPStroke(tool: PPTCsI.tool, width: PPTCsI.width, color: PPTCsI.color)
        }
        
        // Construct a sample squiggle
        let windowSize = previewWindow!.frame.size.height
        stroke.addPoint(CGPointMake(windowSize * 0.10, windowSize * 0.9), withPressure: 0.5)
        stroke.addPoint(CGPointMake(windowSize * 0.25, windowSize * 0.8), withPressure: 0.6)
        stroke.addPoint(CGPointMake(windowSize * 0.40, windowSize * 0.7), withPressure: 0.8)
        stroke.addPoint(CGPointMake(windowSize * 0.55, windowSize * 0.6), withPressure: 1.0)
        stroke.addPoint(CGPointMake(windowSize * 0.50, windowSize * 0.5), withPressure: 1.0)
        stroke.addPoint(CGPointMake(windowSize * 0.45, windowSize * 0.4), withPressure: 1.0)
        stroke.addPoint(CGPointMake(windowSize * 0.60, windowSize * 0.3), withPressure: 0.8)
        stroke.addPoint(CGPointMake(windowSize * 0.75, windowSize * 0.2), withPressure: 0.6)
        stroke.addPoint(CGPointMake(windowSize * 0.90, windowSize * 0.1), withPressure: 0.5)
        
        return stroke
    }
}


extension PPToolConfigurationViewController : UICollectionViewDataSource{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 14
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Static list of colors to choose from
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("colorCell", forIndexPath: indexPath)
        cell.backgroundColor = colors[indexPath.row % colors.count]
        
        // Highlight the currently active color
        if (cell.backgroundColor == PPToolConfiguration.sharedInstance.color){
            cell.layer.borderColor = UIColor.whiteColor().CGColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderWidth = 0
        }
        
        return cell
    }
}


extension PPToolConfigurationViewController : UICollectionViewDelegate{
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        PPToolConfiguration.sharedInstance.color = colors[indexPath.row % colors.count]
    }
}


extension UIColor{
    // Extend UIColor to accept hex colors
    convenience init(hex: String) {
        let characterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characterSet.formUnionWithCharacterSet(NSCharacterSet(charactersInString: "#"))
        let cString = hex.stringByTrimmingCharactersInSet(characterSet).uppercaseString
        if (cString.characters.count != 6) {
            self.init(white: 1.0, alpha: 1.0)
        } else {
            var rgbValue: UInt32 = 0
            NSScanner(string: cString).scanHexInt(&rgbValue)
            
            self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: CGFloat(1.0))
        }
    }
}