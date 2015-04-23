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
    
    
    // MARK: Tumblr session handling
    
    func logInToTumblr(){
        // Present Tumblr login modal
        TMAPIClient.sharedInstance().authenticate("pinchpad", callback: { (error: NSError!) -> Void in
            println("Tumblr login error?: \(error)")
            // If there was an error, print it and return
            if let error = error {
                println(error)
                return
            }
            
            // Otherwise, we need to figure out which specific blog we're posting to
            // To do this, we'll need to fetch user info for the current user
            TMAPIClient.sharedInstance().userInfo({ (result:AnyObject!, error:NSError!) -> Void in
                var tumblrInfoToPersist: [String: String] = [:]  // Init an empty dict
                tumblrInfoToPersist["Token"] = TMAPIClient.sharedInstance().OAuthToken
                tumblrInfoToPersist["Secret"] = TMAPIClient.sharedInstance().OAuthTokenSecret
                
                println(JSON(result)["user"]["blogs"])
                if let blogs = JSON(result)["user"]["blogs"].array {
                    if blogs.count >= 1{
                        // Automatically select the user's first blog
                        tumblrInfoToPersist["Blog"] = blogs[0]["name"].string
                        
                        // TODO: have the user pick a blog manually if they have 2+ blogs
                        tumblrInfoToPersist["Blog"] = "tibetanrockdogtranslations"
                        
                        Locksmith.saveData(tumblrInfoToPersist, forUserAccount:"Tumblr")
                    }
                }
            })
        })
    }
    
    func logOutOfTumblr() {
        TMAPIClient.sharedInstance().OAuthToken = ""
        TMAPIClient.sharedInstance().OAuthTokenSecret = ""
        Locksmith.deleteDataForUserAccount("Tumblr")
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
        let composer = TWTRComposer()
        
        // Format the date
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "h:mma"
        let caption = "\(dateFormatter.stringFromDate(date)), \(timeFormatter.stringFromDate(date).lowercaseString)"
        
//        composer.postStatus("\(caption) #pinchpad", image:image){
//            (success: Bool) in
//            println("how'd it go? \(success)")        // print whether we succeeded
//            if (success){
//                self.canvas.contentView.clear()
//            }
//        }
        
        self.postToTumblr(caption: caption)
    }
    
    func postToTumblr(#caption: String){
        let (dictionary, error) = Locksmith.loadDataForUserAccount("Tumblr")
        if let dict = dictionary, blogName = dict["Blog"] as? String where error == nil {
            var image = self.canvas.contentView.asImage()
            var imageData = UIImagePNGRepresentation(image)
            TMAPIClient.sharedInstance().photo(blogName, imageNSDataArray: [imageData], contentTypeArray: ["image/png"], fileNameArray: ["test.png"], parameters: ["caption":caption, "tags":"pinchpad", "link":"http://www.pinchpad.com"], callback: { (response: AnyObject!, error: NSError!) -> Void in
                if let error = error{
                    println(error)
                } else {
                    println(response)
                }
            })
        }
    }
    
    
    // MARK: Settings menu
    
    @IBAction func showActionSheet(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let twitterLoggedIn = (Twitter.sharedInstance().session() != nil)
        let tumblrLoggedIn = (TMAPIClient.sharedInstance().OAuthToken != nil && TMAPIClient.sharedInstance().OAuthToken != "")
        
        // Set up buttons
        let twitterAction = UIAlertAction(title: (twitterLoggedIn ? "Auto-post to Twitter: \(Twitter.sharedInstance().session().userName)" : "Auto-post to Twitter: OFF"), style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            if (twitterLoggedIn){
                self.logOutOfTwitter()
            } else {
                self.logInToTwitter()
            }
        })
        let tumblrAction = UIAlertAction(title: (tumblrLoggedIn ? "Auto-post to Tumblr: ON" : "Auto-post to Tumblr: OFF"), style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            if (tumblrLoggedIn){
                self.logOutOfTumblr()
            } else {
                self.logInToTumblr()
            }
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

