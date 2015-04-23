//
//  AuthManager.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 4/23/15.
//
//

import TwitterKit
import TMTumblrSDK
import Locksmith

class AuthManager {
    // MARK: Initialization
    
    class func start(){
        // Load Twitter and Tumblr API keys info from Configuration.plist
        // Also restore persisted info about Tumblr login
        if let config = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Configuration", ofType:"plist")!){
            // Twitter
            if let twitter = config["TwitterAPI"] as? NSDictionary, consumerKey = twitter["ConsumerKey"] as? String, consumerSecret = twitter["ConsumerSecret"] as? String{
                Twitter.sharedInstance().startWithConsumerKey(consumerKey, consumerSecret:consumerSecret)
                
                // Check if we're already logged in to Twitter, and if so, print it to the log
                // (Restoring persisted login info is handled automatically by the Twitter framework)
                if (AuthManager.isLoggedIn(.Twitter)){
                    println("Logged in to Twitter as \(AuthManager.identifier(.Twitter)!)")
                }
            }
            
            // Tumblr
            if let tumblr = config["TumblrAPI"] as? NSDictionary, consumerKey = tumblr["ConsumerKey"] as? String, consumerSecret = tumblr["ConsumerSecret"] as? String{
                TMAPIClient.sharedInstance().OAuthConsumerKey = consumerKey
                TMAPIClient.sharedInstance().OAuthConsumerSecret = consumerSecret
                
                // Check if we're already logged in to Tumblr, and if so, load data and print it to the log
                // (We have to manually restory the user's OAuth token from the keychain)
                if (AuthManager.isLoggedIn(.Tumblr)){
                    AuthManager.loadKeychainData(.Tumblr)
                    println("Logged in to Tumblr as \(AuthManager.identifier(.Tumblr)!)")
                }
            }
        }
    }
    
    class func loadKeychainData(service: AuthManagerService){
        if (service == .Tumblr){
            let (dictionary, error) = Locksmith.loadDataForUserAccount("Tumblr")
            if let dict = dictionary, token = dict["Token"] as? String, secret = dict["Secret"] as? String, blog = dict["Blog"] as? String where error == nil {
                TMAPIClient.sharedInstance().OAuthToken = token
                TMAPIClient.sharedInstance().OAuthTokenSecret = secret
            }
        }
    }
    
    
    // MARK: Checking auth state
    
    class func isLoggedIn(service: AuthManagerService) -> Bool{
        if (service == .Twitter){
            return (Twitter.sharedInstance().session() != nil)
        } else if (service == .Tumblr){
            let (dictionary, error) = Locksmith.loadDataForUserAccount("Tumblr")
            if let dict = dictionary, token = dict["Token"] as? String, secret = dict["Secret"] as? String, blog = dict["Blog"] as? String where error == nil {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    class func identifier(service: AuthManagerService) -> String?{
        if (!isLoggedIn(service)){
            return nil
        } else if (service == .Twitter){
            return Twitter.sharedInstance().session().userName
        } else if (service == .Tumblr){
            let (dictionary, error) = Locksmith.loadDataForUserAccount("Tumblr")
            if let dict = dictionary {
                return dict["Blog"] as? String
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

enum AuthManagerService{
    case Twitter
    case Tumblr
}