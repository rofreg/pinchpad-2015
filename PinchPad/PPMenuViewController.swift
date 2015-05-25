//
//  PPMenuViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/25/15.
//
//

import UIKit

class PPMenuViewController : UIViewController{
    
    @IBAction func twitter(){
        println(AuthManager.isLoggedIn(.Twitter) ? "Auto-post to Twitter: \(AuthManager.identifier(.Twitter)!)" : "Auto-post to Twitter: OFF")
        AuthManager.changeAuth(.Twitter)
    }
    
    @IBAction func tumblr(){
        AuthManager.changeAuth(.Tumblr)
    }
    
    @IBAction func clearCanvas(){
        NSNotificationCenter.defaultCenter().postNotificationName("PPClearCanvas", object: self)
    }
}