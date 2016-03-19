//
//  AppConfiguration.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/25/15.
//
//

class AppConfiguration {
    // Set up a singleton instance
    static let sharedInstance = AppConfiguration()
    
    var widerCanvas: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "widerCanvas")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            // We changed the canvas size, so clear the canvas
            NSNotificationCenter.defaultCenter().postNotificationName("PPResizeCanvas", object: self)
        }
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("widerCanvas") ?? false
        }
    }
    
    var frameLength: Double = 0.5 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("PPFrameLengthDidChange", object: self)
        }
    }
}