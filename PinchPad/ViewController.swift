//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/2/15.
//
//

import UIKit
import TwitterKit
import TMTumblrSDK
import Locksmith
import SwiftyJSON

class ViewController: UIViewController, WacomDiscoveryCallback, WacomStylusEventCallback {
    @IBOutlet var canvas: PPInfiniteScrollView!
    @IBOutlet var toolConfigurationViewContainer: UIView!
   
    override func viewDidLoad() {
        WacomManager.getManager().registerForNotifications(self)
        WacomManager.getManager().startDeviceDiscovery()
        TouchManager.GetTouchManager().touchRejectionEnabled = true
        TouchManager.GetTouchManager().timingOffset = 200000
        
        // When our data changes, update the display
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updatePendingPostsDisplay"), name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)
        
        super.viewDidLoad()
    }
    
    deinit {
        WacomManager.getManager().stopDeviceDiscovery()
    }
    
    
    // MARK: tool handling
    
    @IBAction func pencil(){
        toolConfigurationViewContainer.hidden = !toolConfigurationViewContainer.hidden
    }
    
    @IBAction func undo(){
        self.canvas.undo()
    }
    
    @IBAction func redo(){
        self.canvas.redo()
    }
    
    @IBAction func post(){
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7
        let image = self.canvas.contentView.asImage()
        
        // Don't post if we haven't drawn any strokes
        if (self.canvas.contentView.strokes.count == 0){
            return
        }
        
        // Format the date
        let date = NSDate(), dateFormatter = NSDateFormatter(), timeFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        timeFormatter.dateFormat = "h:mma"
        let caption = "\(dateFormatter.stringFromDate(date)), \(timeFormatter.stringFromDate(date).lowercaseString)"
        
        // Actually post
        for service in AuthManager.loggedInServices(){
            println("Posting to service #\(service.rawValue+1)")
            AuthManager.enqueue(service, image: image, caption: caption)
        }
        
        // Clear the canvas
        self.canvas.clear()
    }
    
    
    // MARK: Settings menu
    
    @IBAction func showActionSheet(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // Set up buttons
        let twitterAction = UIAlertAction(title: (AuthManager.isLoggedIn(.Twitter) ? "Auto-post to Twitter: \(AuthManager.identifier(.Twitter)!)" : "Auto-post to Twitter: OFF"), style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            AuthManager.changeAuth(.Twitter)
        })
        let tumblrAction = UIAlertAction(title: (AuthManager.isLoggedIn(.Tumblr) ? "Auto-post to Tumblr: \(AuthManager.identifier(.Tumblr)!)" : "Auto-post to Tumblr: OFF"), style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            AuthManager.changeAuth(.Tumblr)
        })
        let clearAction = UIAlertAction(title: "Clear canvas", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            self.canvas.clear()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        // Add buttons
        optionMenu.addAction(twitterAction)
        optionMenu.addAction(tumblrAction)
        optionMenu.addAction(clearAction)
        optionMenu.addAction(cancelAction)
        
        // Show menu
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    
    // MARK: Pending post display handling
    func updatePendingPostsDisplay(){
        let fetchRequest = NSFetchRequest(entityName: "Sketch")
        if let fetchResults = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil) as? [Sketch] {
            println("Updated posts-to-sync count: \(fetchResults.count)")
        }
    }
}



// MARK: Wacom extras
extension ViewController: WacomDiscoveryCallback, WacomStylusEventCallback {
    // MARK: Wacom device discovery
    
    func deviceDiscovered(device: WacomDevice!) {
        println("Wacom device discovered!")
        if (WacomManager.getManager().isDiscoveryInProgress &&
            !WacomManager.getManager().isADeviceSelected() &&
            !device.isCurrentlyConnected()){
                WacomManager.getManager().selectDevice(device)
        }
    }
    
    func discoveryStatePoweredOff(){
        println("Welp, looks like Bluetooth is off")
        
        // Bluetooth is disabled
        // TODO: show an alert, or modify the UI
    }
    
    
    // MARK: Wacom device actions
    
    func stylusEvent(stylusEvent: WacomStylusEvent!) {
        let type = stylusEvent.getType()
        
        if (type == WacomStylusEventType.eStylusEventType_PressureChange){
            PPToolConfiguration.sharedInstance.pressure =
                stylusEvent.getPressure() / CGFloat(WacomManager.getManager().getSelectedDevice().getMaximumPressure())
        } else if (type == WacomStylusEventType.eStylusEventType_ButtonPressed) {
            PPToolConfiguration.sharedInstance.tool = PPToolType.Eraser
            println("Button down: \(stylusEvent.getButton())")
        } else if (type == WacomStylusEventType.eStylusEventType_ButtonReleased) {
            PPToolConfiguration.sharedInstance.tool = PPToolType.Brush
            println("Button up: \(stylusEvent.getButton())")
        } else if (type == WacomStylusEventType.eStylusEventType_BatteryLevelChanged) {
            // TODO: battery warning
            // println("Battery level: \(stylusEvent.getBatteryLevel())")
        }
    }
}

