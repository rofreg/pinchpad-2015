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

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Check that the user is logged in
        if Twitter.sharedInstance().session() == nil {
            logIn()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func logIn(){
        // Present Twitter login modal
        Twitter.sharedInstance().logInWithCompletion{(session: TWTRSession!, error: NSError!) -> Void in
            if session != nil {
                // We logged in successfully
                println(session.userName)
            }
        }
        
        // Note: if the user cancels Twitter login, they will be returned to the main screen
        // That in turn will trigger viewDidAppear, and the Twitter login screen will re-open in an infinite loop
        // This is intentional – the user MUST log in with Twitter before they can do anything else
    }
    
    @IBAction func logOut(sender: UIButton) {
        Twitter.sharedInstance().logOut()
        logIn()
    }
}

