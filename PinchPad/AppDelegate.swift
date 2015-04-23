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
import TMTumblrSDK
import Crashlytics
import Locksmith

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
                if (Twitter.sharedInstance().session() != nil){
                    println("Logged in to Twitter as \(Twitter.sharedInstance().session().userName)")
                }
            }
            if let tumblr = (config["TumblrAPI"] as? NSDictionary){
                var consumerKey = tumblr["ConsumerKey"] as! String
                var consumerSecret = tumblr["ConsumerSecret"] as! String
                TMAPIClient.sharedInstance().OAuthConsumerKey = consumerKey
                TMAPIClient.sharedInstance().OAuthConsumerSecret = consumerSecret
                let (dictionary, error) = Locksmith.loadDataForUserAccount("Tumblr")
                if let dict = dictionary where error == nil {
                    // Load OAuth tokens from the keychain
                    if let token = dict["Token"] as? String, secret = dict["Secret"] as? String, blog = dict["Blog"] as? String{
                        TMAPIClient.sharedInstance().OAuthToken = token
                        TMAPIClient.sharedInstance().OAuthTokenSecret = secret
                        println("Logged in to Tumblr as \(blog)")
                    }
                }
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
