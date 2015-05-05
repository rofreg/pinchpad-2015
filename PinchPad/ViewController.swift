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
    @IBOutlet var pendingPostsView: UIView!
    @IBOutlet var pendingPostsLabel: UILabel!
    @IBOutlet var pendingPostsRetryButton: UIButton!
    
    @IBOutlet var pencilButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    
    var lastTool = PPToolType.Brush
   
    override func viewDidLoad() {
        WacomManager.getManager().registerForNotifications(self)
        WacomManager.getManager().startDeviceDiscovery()
        TouchManager.GetTouchManager().touchRejectionEnabled = true
        TouchManager.GetTouchManager().timingOffset = 200000
        
        // When our data changes, update the display
        self.updatePendingPostsDisplay()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updatePendingPostsDisplay"), name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)
        
        // When our tool changes, update the display
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateToolbarDisplay"), name: "PPToolConfigurationChanged", object: nil)
        
        super.viewDidLoad()
    }
    
    deinit {
        WacomManager.getManager().stopDeviceDiscovery()
    }
    
    
    // MARK: tool handling
    
    @IBAction func pencil(){
        if (PPToolConfiguration.sharedInstance.tool != .Eraser){
            // Toggle config menu if the pencil or brush is already selected
            toolConfigurationViewContainer.hidden = !toolConfigurationViewContainer.hidden
        } else {
            // Otherwise, switch to last tool
            PPToolConfiguration.sharedInstance.tool = lastTool
        }
    }
    
    @IBAction func eraser(){
        if (PPToolConfiguration.sharedInstance.tool == .Eraser){
            // Toggle config menu if the eraser is already selected
            toolConfigurationViewContainer.hidden = !toolConfigurationViewContainer.hidden
        } else {
            // Otherwise, switch to eraser (but remember what tool we were using last)
            lastTool = PPToolConfiguration.sharedInstance.tool
            PPToolConfiguration.sharedInstance.tool = .Eraser
        }
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
        fetchRequest.predicate = NSPredicate(format: "syncStarted == nil", NSDate().dateByAddingTimeInterval(-60))
        let unsynced = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil)
        
        fetchRequest.predicate = NSPredicate(format: "syncError == true")
        let syncErrors = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil)
        
        if let syncErrors = syncErrors where syncErrors.count > 0{
            pendingPostsView.alpha = 1
            pendingPostsRetryButton.hidden = false
            var pluralPosts = (syncErrors.count == 1 ? "post" : "posts")
            pendingPostsLabel.text = "\(syncErrors.count) \(pluralPosts) failed to sync"
        } else if let unsynced = unsynced where unsynced.count > 0{
            pendingPostsView.alpha = 1
            pendingPostsRetryButton.hidden = true
            pendingPostsLabel.text = "Posting..."
        } else {
            pendingPostsRetryButton.hidden = true
            pendingPostsLabel.text = "Post submitted!"
            UIView.animateWithDuration(0.5, delay: 2.0, options: nil, animations: { () -> Void in
                self.pendingPostsView.alpha = 0
            }, completion: nil)
        }
    }
    
    @IBAction func retry(){
        AuthManager.sync()
    }
    
    
    // MARK: Toolbar display handling
    
    func updateToolbarDisplay(){
        if (PPToolConfiguration.sharedInstance.tool == .Eraser){
            pencilButton.tintColor = UIColor.lightGrayColor()
            eraserButton.tintColor = self.view.tintColor
        } else {
            pencilButton.tintColor = self.view.tintColor
            eraserButton.tintColor = UIColor.lightGrayColor()
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

