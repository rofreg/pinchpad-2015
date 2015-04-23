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
        // Load Twitter and Tumblr info
        AuthManager.start()
        Fabric.with([Twitter(), Crashlytics()])
        
        return true
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        // Handle redirects after authenticating with Tumblr via Safari
        TMAPIClient.sharedInstance().handleOpenURL(url)
        return true
    }
}
