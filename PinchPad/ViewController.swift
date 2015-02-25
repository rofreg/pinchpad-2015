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

class ViewController: UIViewController {
    @IBOutlet var canvas: PPInfiniteScrollView!
    var toolConfigurationViewController: PPToolConfigurationViewController!
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ToolConfigurationSegue"{
            toolConfigurationViewController = segue.destinationViewController as PPToolConfigurationViewController
            toolConfigurationViewController.delegate = canvas.contentView
        }
    }
    
    
    @IBAction func toolChanged(){
        println("tool change")
        
    }
    
    func widthChanged(newWidth: Float){
        println("tool change")
        
    }
    
    
    @IBAction func pencil(){
        println("WOO")
        
    }
    
    @IBAction func undo(){
        self.canvas.undo()
    }
    
    @IBAction func redo(){
        self.canvas.redo()
    }
    
    @IBAction func showActionSheet(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let twitterLoggedIn = (Twitter.sharedInstance().session() != nil)
        let tumblrLoggedIn = (false)
        
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
//        let tumblrAction = UIAlertAction(title: (tumblrLoggedIn ? "Auto-post to Tumblr: ON" : "Auto-post to Tumblr: OFF"), style: .Default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            println("Tumblr status changed")
//        })
        let clearAction = UIAlertAction(title: "Clear canvas", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Clear canvas")
            self.canvas.clear()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        // Add buttons
        optionMenu.addAction(twitterAction)
//        optionMenu.addAction(tumblrAction)
        optionMenu.addAction(clearAction)
        optionMenu.addAction(cancelAction)
        
        // Show menu
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
}

