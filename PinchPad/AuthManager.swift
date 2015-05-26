//
//  AuthManager.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 4/23/15.
//
//

import UIKit
import TwitterKit
import TMTumblrSDK
import Locksmith
import SwiftyJSON

class AuthManager {
    class func managedContext() -> NSManagedObjectContext{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.managedObjectContext!
    }
    
    
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
    
    
    // MARK: Changing auth state
    
    class func logIn(service: AuthManagerService){
        if (service == .Twitter){
            // Present Twitter login modal
            Twitter.sharedInstance().logInWithCompletion({ (_, _) -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("PPAuthChanged", object: nil)
            })
        } else if (service == .Tumblr){
            // Present Tumblr login by switching to Safari
            TMAPIClient.sharedInstance().authenticate("pinchpad", callback: { (error: NSError!) -> Void in
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
                    
                    // Which specific blog should we post to?
                    if let blogs = JSON(result)["user"]["blogs"].array {
                        if (blogs.count == 1){
                            // Automatically select the user's first blog
                            tumblrInfoToPersist["Blog"] = blogs[0]["name"].string!
                            Locksmith.updateData(tumblrInfoToPersist, forUserAccount:"Tumblr")
                            NSNotificationCenter.defaultCenter().postNotificationName("PPAuthChanged", object: nil)
                        } else if (blogs.count > 1){
                            // Have the user pick manually if they have 2+ blogs
                            let blogChoiceMenu = UIAlertController(title: "Which blog do you want to post to?", message: nil, preferredStyle: .ActionSheet)
                            
                            // Add a button for each blog choice
                            for blog in blogs{
                                let button = UIAlertAction(title: blog["name"].string!, style: .Default, handler: {
                                    (alert: UIAlertAction!) -> Void in
                                    tumblrInfoToPersist["Blog"] = blog["name"].string!
                                    Locksmith.updateData(tumblrInfoToPersist, forUserAccount:"Tumblr")
                                    NSNotificationCenter.defaultCenter().postNotificationName("PPAuthChanged", object: nil)
                                })
                                blogChoiceMenu.addAction(button)
                            }
                            
                            // Add a cancel button
                            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
                                (alert: UIAlertAction!) -> Void in
                                Locksmith.deleteDataForUserAccount("Tumblr")
                            })
                            blogChoiceMenu.addAction(cancelAction)
                            
                            // Display the action sheet
                            var vc = UIApplication.sharedApplication().delegate!.window!!.rootViewController
                            vc!.presentViewController(blogChoiceMenu, animated: true, completion: nil)
                        }
                    }
                })
            })
        } else {
            return
        }
    }
    
    class func logOut(service: AuthManagerService){
        if (service == .Twitter){
            Twitter.sharedInstance().logOut()
        } else if (service == .Tumblr){
            // Clear Tumblr SDK vars and keychain
            TMAPIClient.sharedInstance().OAuthToken = ""
            TMAPIClient.sharedInstance().OAuthTokenSecret = ""
            Locksmith.deleteDataForUserAccount("Tumblr")
        } else {
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("PPAuthChanged", object: nil)
    }
    
    class func changeAuth(service: AuthManagerService){
        let loggingIn = !AuthManager.isLoggedIn(service)
        if (loggingIn){
            AuthManager.logIn(service)
        } else {
            AuthManager.logOut(service)
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
    
    class func loggedInServices() -> [AuthManagerService]{
        return [AuthManagerService.Twitter, AuthManagerService.Tumblr].filter({
            return AuthManager.isLoggedIn($0)
        })
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
    
    
    // MARK: Posting new content
    
    class func enqueue(service: AuthManagerService, image: UIImage, caption: String){
        // Save this new item-to-be-posted to CoreData
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Sketch", inManagedObjectContext: AuthManager.managedContext()) as! Sketch
        newItem.createdAt = NSDate()
        newItem.rawService = service.rawValue
        newItem.imageData = UIImagePNGRepresentation(image)
        newItem.caption = caption
        newItem.duration = 0
        AuthManager.managedContext().save(nil)
        
        // Then attempt to sync the new item, along with any other older unsynced items
        AuthManager.sync()
    }
    
    class func sync(){
        println("Sync started!")
        
        // Try to sync any sketches that aren't already trying to sync
        // (Make an exception for expenses that ARE "trying to sync", but have been trying for 60+ seconds)
        // (Those posts should try to sync again, even if it might result in a double-post)
        // (Also ignore sketches with an explicit duration; they're part of a pending ANIMATION post)
        let fetchRequest = NSFetchRequest(entityName: "Sketch")
        fetchRequest.predicate = NSPredicate(format: "(syncStarted == nil OR syncStarted < %@) AND (duration = 0)", NSDate().dateByAddingTimeInterval(-60))
        
        if let fetchResults = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil) as? [Sketch] {
            println("Syncing \(fetchResults.count) sketches")
            for sketch in fetchResults{
                sketch.syncStarted = NSDate()
                AuthManager.managedContext().save(nil)
                AuthManager.post(sketch)
            }
        }
    }
    
    class func post(sketch: Sketch){
        let service = AuthManagerService(rawValue: sketch.rawService)
        let image = UIImage(data: sketch.imageData)
        
        if (service == .Twitter){
            let composer = TWTRComposer()
            composer.postStatus("\(sketch.caption) #pinchpad", image:image){
                (success: Bool) in
                println("Posted to Twitter: \(success)")        // print whether we succeeded
                if (success){
                    // Delete successful post from local DB
                    AuthManager.managedContext().deleteObject(sketch)
                } else {
                    sketch.syncError = true
                }
                sketch.syncStarted = nil
                AuthManager.managedContext().save(nil)
            }
        } else if (service == .Tumblr) {
            TMAPIClient.sharedInstance().photo(AuthManager.identifier(.Tumblr), imageNSDataArray: [sketch.imageData], contentTypeArray: ["image/png"], fileNameArray: ["test.png"], parameters: ["tags":"pinchpad,hourly comics", "link":"http://www.pinchpad.com"], callback: { (response: AnyObject!, error: NSError!) -> Void in
                // Parse the JSON response to see if we saved correctly
                var success: Bool
                if let responseDict = response as? NSDictionary, responseId: AnyObject? = response["id"] where error == nil {
                    success = true
                } else {
                    success = false
                }
                
                println("Posted to Tumblr: \(success)")        // print whether we succeeded
                if (success){
                    // Delete successful post from local DB
                    AuthManager.managedContext().deleteObject(sketch)
                } else {
                    sketch.syncError = true
                }
                sketch.syncStarted = nil
                AuthManager.managedContext().save(nil)
            })
        }
    }
}

enum AuthManagerService : Int16{
    case Twitter
    case Tumblr
}