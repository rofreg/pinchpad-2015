//
//  PPMenuViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/25/15.
//
//

import UIKit

class PPMenuViewController : UIViewController{
    @IBOutlet var twitterButton: UIButton!
    @IBOutlet var tumblrButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var widerCanvasSwitch: UISwitch!
    
    var disabledColor = UIColor(white: 0.2, alpha: 1.0)
    var twitterColor = UIColor(red: 0/255.0, green: 176/255.0, blue: 237/255.0, alpha: 1.0)
    var tumblrColor = UIColor(red: 52/255.0, green: 70/255.0, blue: 93/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        twitterButton.titleLabel?.numberOfLines = 2
        tumblrButton.titleLabel?.numberOfLines = 2
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("refreshInfo"), name: "PPAuthChanged", object: nil)
        
        clearButton.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    override func viewWillAppear(animated: Bool) {
        refreshInfo()
    }
    
    func refreshInfo(){
        // Twitter
        if (AuthManager.isLoggedIn(.Twitter)){
            twitterButton.backgroundColor = twitterColor
            var attrString = NSMutableAttributedString(string: "Connected as\n")
            attrString.appendAttributedString(NSAttributedString(string: AuthManager.identifier(.Twitter)!, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]))
            twitterButton.setAttributedTitle(attrString, forState: .Normal)
            twitterButton.alpha = 1.0
        } else {
            twitterButton.backgroundColor = disabledColor
            twitterButton.setTitle("Not connected", forState: .Normal)
            twitterButton.alpha = 0.3
        }
        
        // Tumblr
        if (AuthManager.isLoggedIn(.Tumblr)){
            tumblrButton.backgroundColor = tumblrColor
            var attrString = NSMutableAttributedString(string: "Connected as\n")
            attrString.appendAttributedString(NSAttributedString(string: AuthManager.identifier(.Tumblr)!, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(14)]))
            tumblrButton.setAttributedTitle(attrString, forState: .Normal)
            tumblrButton.alpha = 1.0
        } else {
            tumblrButton.backgroundColor = disabledColor
            tumblrButton.setTitle("Not connected", forState: .Normal)
            tumblrButton.alpha = 0.3
        }
        
        // Wider canvas toggle
        widerCanvasSwitch.setOn(PPAppConfiguration.sharedInstance.widerCanvas, animated: false)
    }
    
    
    // MARK: Menu buttons
    
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
    
    @IBAction func widerCanvasToggle(sender: UISwitch){
        PPAppConfiguration.sharedInstance.widerCanvas = sender.on
    }
}