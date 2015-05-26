//
//  PPAppConfiguration.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/25/15.
//
//

class PPAppConfiguration {
    // Set up a singleton instance
    // TODO: there's a less verbose format for this in Swift 1.2
    class var sharedInstance: PPAppConfiguration {
        struct Static {
            static let instance: PPAppConfiguration = PPAppConfiguration()
        }
        return Static.instance
    }
    
    var widerCanvas: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "widerCanvas")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            // We changed the canvas size, so clear the canvas
            NSNotificationCenter.defaultCenter().postNotificationName("PPResizeCanvas", object: self)
        }
        get {
            var val: Bool? = NSUserDefaults.standardUserDefaults().boolForKey("widerCanvas")
            
            if let actualVal = val{
                return actualVal
            } else {
                return false
            }
        }
    }
    
    var frameLength: Double = 0.5 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("PPFrameLengthDidChange", object: self)
        }
    }
}