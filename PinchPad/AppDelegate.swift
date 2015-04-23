//
//  AppDelegate.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/2/15.
//
//

import UIKit
import Fabric
import TwitterKit
import Crashlytics
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Load Twitter and Tumblr API keys info from Configuration.plist
        if let config = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Configuration", ofType:"plist")!){
            if let twitter = (config["TwitterAPI"] as? NSDictionary){
                var consumerKey = twitter["ConsumerKey"] as! String
                var consumerSecret = twitter["ConsumerSecret"] as! String
                Twitter.sharedInstance().startWithConsumerKey(consumerKey, consumerSecret:consumerSecret)
            }
            if let tumblr = (config["TumblrAPI"] as? NSDictionary){
                var consumerKey = tumblr["ConsumerKey"] as! String
                var consumerSecret = tumblr["ConsumerSecret"] as! String
                TMAPIClient.sharedInstance().OAuthConsumerKey = consumerKey
                TMAPIClient.sharedInstance().OAuthConsumerSecret = consumerSecret
            }
        }
    
        Fabric.with([Twitter(), Crashlytics()])
        
        return true
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        TMAPIClient.sharedInstance().handleOpenURL(url)
        return true
    }
}
