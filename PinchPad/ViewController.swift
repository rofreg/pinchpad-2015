//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/2/15.
//
//

import UIKit
import TwitterKit
import CoreData

class ViewController: UIViewController, WacomDiscoveryCallback, WacomStylusEventCallback {
    @IBOutlet var canvas: PPInfiniteScrollView!
    var toolConfigurationViewController: PPToolConfigurationViewController!
   
    override func viewDidLoad() {
        WacomManager.getManager().registerForNotifications(self)
        WacomManager.getManager().startDeviceDiscovery()
        TouchManager.GetTouchManager().touchRejectionEnabled = true
        TouchManager.GetTouchManager().timingOffset = 200000
    }
    
    deinit {
        WacomManager.getManager().stopDeviceDiscovery()
    }
    
    
    // MARK: Twitter session handling
    
    func logInToTwitter(){
        // Present Twitter login modal
        Twitter.sharedInstance().logInWithCompletion{(session: TWTRSession!, error: NSError!) -> Void in
            if session != nil {
                // We logged in successfully
                println(session.userName)
                println(session)
            }
        }
    }
    
    func logOutOfTwitter() {
        Twitter.sharedInstance().logOut()
    }
    
    
    // MARK: tool handling
    
    @IBAction func pencil(){
        println("WOO")
        
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
        let composer = TWTRComposer()
        composer.postStatus("This is a test post from my Pinch Pad app. Whee!", image:image){
            (success: Bool) in
            println("how'd it go? \(success)")        // print whether we succeeded
        }
    }
    
    
    // MARK: Settings menu
    
    @IBAction func showActionSheet(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let twitterLoggedIn = (Twitter.sharedInstance().session() != nil)
        let tumblrLoggedIn = (rand() % 2 == 0)
        
        // Set up buttons
        let twitterAction = UIAlertAction(title: (twitterLoggedIn ? "Auto-post to Twitter: ON" : "Auto-post to Twitter: OFF"), style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            if (Twitter.sharedInstance().session() == nil){
                self.logInToTwitter()
            } else {
                self.logOutOfTwitter()
            }
            println("Twitter status changed")
        })
        let tumblrAction = UIAlertAction(title: (tumblrLoggedIn ? "Auto-post to Tumblr: ON" : "Auto-post to Tumblr: OFF"), style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Tumblr status changed")
        })
        let clearAction = UIAlertAction(title: "Clear canvas", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Clear canvas")
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
        
        if (type == WacomStylusEventType.StylusEventType_PressureChange){
            PPToolConfiguration.sharedInstance.pressure =
                stylusEvent.getPressure() / CGFloat(WacomManager.getManager().getSelectedDevice().getMaximumPressure())
        } else if (type == WacomStylusEventType.StylusEventType_ButtonPressed) {
            PPToolConfiguration.sharedInstance.tool = PPToolType.Eraser
            println("Button down: \(stylusEvent.getButton())")
        } else if (type == WacomStylusEventType.StylusEventType_ButtonReleased) {
            PPToolConfiguration.sharedInstance.tool = PPToolType.Brush
            println("Button up: \(stylusEvent.getButton())")
        } else if (type == WacomStylusEventType.StylusEventType_BatteryLevelChanged) {
            // TODO: battery warning
            // println("Battery level: \(stylusEvent.getBatteryLevel())")
        }
    }
}

