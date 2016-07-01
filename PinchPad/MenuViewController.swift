//
//  MenuViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/25/15.
//
//

import UIKit
import CoreData
import MessageUI

class MenuViewController : UIViewController{
    @IBOutlet var twitterButton: UIButton!
    @IBOutlet var tumblrButton: UIButton!
    @IBOutlet var frameLengthLabel: UILabel!
    @IBOutlet var frameLengthStepper: UIStepper!
    @IBOutlet var addFrameButton: UIButton!
    @IBOutlet var removeFrameButton: UIButton!
    @IBOutlet var previewButton: UIButton!
    @IBOutlet var widerCanvasSwitch: UISwitch!
    @IBOutlet var clearButton: UIButton!
    
    let disabledColor = UIColor(white: 0.2, alpha: 1.0)
    let twitterColor = UIColor(red: 0/255.0, green: 176/255.0, blue: 237/255.0, alpha: 1.0)
    let tumblrColor = UIColor(red: 52/255.0, green: 70/255.0, blue: 93/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        twitterButton.titleLabel?.numberOfLines = 2
        tumblrButton.titleLabel?.numberOfLines = 2
        for button in [addFrameButton, removeFrameButton, previewButton]{
            button.layer.borderColor = UIColor.whiteColor().CGColor
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MenuViewController.refreshInfo), name: "AuthChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MenuViewController.refreshInfo), name: "FrameLengthDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MenuViewController.refreshInfo), name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        refreshInfo()
    }
    
    func refreshInfo(){
        // Update Twitter and Tumblr buttons
        let integrations = [AuthManagerService.Twitter: twitterButton, AuthManagerService.Tumblr: tumblrButton]
        for (service, button) in integrations{
            if (AuthManager.isLoggedIn(service)){
                button.backgroundColor = (service == .Twitter ? twitterColor : tumblrColor)
                let attrString = NSMutableAttributedString(string: "Connected as\n")
                attrString.appendAttributedString(NSAttributedString(string: AuthManager.identifier(service)!, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]))
                button.setAttributedTitle(attrString, forState: .Normal)
                button.alpha = 1.0
            } else {
                button.backgroundColor = disabledColor
                button.setAttributedTitle(NSAttributedString(string: "Not connected"), forState: .Normal)
                button.alpha = 0.3
            }
        }
        
        // Animation info
        frameLengthStepper.value = AppConfig.sharedInstance.frameLength
        let frameDuration = String(format: "%.1f", frameLengthStepper.value)
        if (UIScreen.mainScreen().bounds.width <= 320){
            frameLengthLabel.text = "\(frameDuration)s"
        } else {
            frameLengthLabel.text = "Show for \(frameDuration)s"
        }
        addFrameButton.setTitle("Add frame #\(Sketch.animationFrameCount + 1)", forState: .Normal)
        let animationStarted = (Sketch.animationFrames.count > 0)
        for button in [previewButton, removeFrameButton]{
            button.alpha = (animationStarted ? 1.0 : 0.5)
        }
        removeFrameButton.enabled = animationStarted
    
        // Wider canvas toggle
        widerCanvasSwitch.setOn(AppConfig.sharedInstance.widerCanvas, animated: false)
    }
    
    
    // MARK: Menu buttons
    
    @IBAction func twitter(){
        AuthManager.changeAuth(.Twitter)
    }
    
    @IBAction func tumblr(){
        AuthManager.changeAuth(.Tumblr)
    }
    
    @IBAction func frameLengthChange(){
        AppConfig.sharedInstance.frameLength = frameLengthStepper.value
    }
    
    @IBAction func addFrame(){
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Sketch", inManagedObjectContext: Sketch.managedContext) as! Sketch
        newItem.createdAt = NSDate()
        newItem.imageData = (self.parentViewController as! ViewController).canvas.asNSData()
        newItem.duration = AppConfig.sharedInstance.frameLength
        _ = try? Sketch.managedContext.save()
    }
    
    @IBAction func removeFrame(){
        if let sketch = Sketch.animationFrames.last{
            Sketch.managedContext.deleteObject(sketch)
            _ = try? Sketch.managedContext.save()
        }
    }
    
    @IBAction func widerCanvasToggle(sender: UISwitch){
        AppConfig.sharedInstance.widerCanvas = sender.on
    }
    
    @IBAction func clearCanvas(){
        NSNotificationCenter.defaultCenter().postNotificationName("ClearCanvas", object: self)
    }
    
    @IBAction func madeByRofreg(){
        UIApplication.sharedApplication().openURL(NSURL(string:"http://www.pinchpad.com")!)
    }
    
    func dismiss(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func sendFeedback(){
        if (MFMailComposeViewController.canSendMail()){
            let version: AnyObject = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]!
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject("Feedback for Pinch Pad (v\(version))")
            mc.setMessageBody("", isHTML: false)
            mc.setToRecipients(["me@rofreg.com"])
            
            self.presentViewController(mc, animated: true, completion: nil)
        } else {
            // Show an alert
            let alert = UIAlertController(title: "No email account found", message: "Whoops, I couldn't find an email account set up on this device! You can send me feedback directly at me@rofreg.com.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

extension MenuViewController : MFMailComposeViewControllerDelegate{
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}