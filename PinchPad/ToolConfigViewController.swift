//
//  ToolConfigViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/8/15.
//
//

import UIKit

class ToolConfigViewController: UIViewController{
    @IBOutlet var toolPicker: UISegmentedControl!
    @IBOutlet var slider: UISlider!
    @IBOutlet var sliderBackground: UIView!
    @IBOutlet var previewWindow: Canvas!
    @IBOutlet var colorCollectionView: UICollectionView!
    let colors = [UIColor.blackColor(), UIColor(hex:"999999"), UIColor(hex:"dddddd"), UIColor(hex:"F2CA42"), UIColor(hex:"00C3A9"), UIColor(hex:"D45354"), UIColor(hex:"2FCAD8"), UIColor(hex:"663300"), UIColor(hex:"af7a56"), UIColor(hex:"ab7dbe"), UIColor(hex:"ff8960"), UIColor(hex:"6e99d4"), UIColor(hex:"4c996e"), UIColor(hex:"dc9bb1")]
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ToolConfigViewController.updatePreview), name: "ToolConfigChanged", object: nil)
        updatePreview()
    }
    
    override func viewDidAppear(animated: Bool) {
        updateSliderBackground()
    }
    
    func updateSliderBackground() {
        for view in sliderBackground.subviews{
            view.removeFromSuperview()
        }
        
        var fullWidth = sliderBackground.frame.width
        let fullHeight = sliderBackground.frame.height
        let adjustmentRadius: CGFloat = 28.0
        fullWidth -= adjustmentRadius
        
        for index in 0...5{
            let tickMark = UIView(frame: CGRectMake(CGFloat(index) * (fullWidth / 5.0) - 1 + adjustmentRadius/2.0, fullHeight * 1.0/4.0 + 0.5, 2, fullHeight * 1.0/2.0))
            tickMark.backgroundColor = (index < Int(slider.value) ? slider.minimumTrackTintColor : UIColor(white: 0.6, alpha: 1.0))
            sliderBackground.addSubview(tickMark)
        }
    }
    
    
    // MARK: Tool configuration IBActions
    
    @IBAction func toolChanged(sender: UISegmentedControl){
        ToolConfig.sharedInstance.tool = Tool(rawValue: sender.selectedSegmentIndex) ?? .Eraser
    }
    
    @IBAction func widthChanged(sender: UISlider){
        let roundedValue = Int(round(sender.value))
        sender.setValue(Float(roundedValue), animated: false)
        
        let realSize = [0.0, 1.0, 3.0, 5.0, 10.0, 30.0, 60.0]
        let toolSize = realSize[roundedValue]
        ToolConfig.sharedInstance.width = CGFloat(toolSize)
        
        updateSliderBackground()
    }
    
    
    // MARK: Stroke preview logic
    
    func updatePreview(){
        // Update the preview canvas
        previewWindow.clear()
        previewWindow.strokes = [previewStroke()]
        if (ToolConfig.sharedInstance.tool == .Eraser){
            // Insert a stroke for the eraser sample to erase
            previewWindow.strokes.insert(previewStroke(.Marker, width: 100), atIndex: 0)
        }
        previewWindow.setNeedsDisplay()
        
        // Update the tool picker if the tool choice changed
        toolPicker.selectedSegmentIndex = ToolConfig.sharedInstance.tool.rawValue
        
        // Update the color picker if the color changed
        colorCollectionView.reloadData()
    }
    
    func previewStroke(tool: Tool = ToolConfig.sharedInstance.tool,
        width: CGFloat = ToolConfig.sharedInstance.width,
        color: UIColor = ToolConfig.sharedInstance.color) -> Stroke{
        
        let stroke = tool.toStrokeType().init(width: width, color: color)
            
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


extension ToolConfigViewController : UICollectionViewDataSource{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("colorCell", forIndexPath: indexPath)
        cell.backgroundColor = colors[indexPath.row % colors.count]
        cell.layer.borderColor = UIColor.whiteColor().CGColor
        
        // Highlight the currently active color
        cell.layer.borderWidth = (cell.backgroundColor == ToolConfig.sharedInstance.color ? 3 : 0)

        return cell
    }
}


extension ToolConfigViewController : UICollectionViewDelegate{
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        ToolConfig.sharedInstance.color = colors[indexPath.row % colors.count]
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