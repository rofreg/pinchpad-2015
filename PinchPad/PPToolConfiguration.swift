//
//  PPToolConfiguration.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/5/15.
//
//

enum PPToolType{
    case Brush
    case Marker
    case Pen
    case Eraser
}

class PPToolConfiguration  {
    // Set up a singleton instance
    static let sharedInstance = PPToolConfiguration()
    
    // List our tool properties
    // Changing any of these properties should send out an NSNotification
    var tool: PPToolType = PPToolType.Brush {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("PPToolConfigurationChanged", object: self) }
    }
    var color: UIColor = UIColor.blackColor() {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("PPToolConfigurationChanged", object: self) }
    }
    var width: CGFloat {
        set {
            self.privateWidth = newValue
            NSNotificationCenter.defaultCenter().postNotificationName("PPToolConfigurationChanged", object: self)
        }
        get {
            // Eraser is automatically wider than the corresponding brush/marker
            return self.privateWidth * (self.tool == .Eraser ? 5 : 1)
        }
    }
    private var privateWidth: CGFloat = 3.0
    var pressure: CGFloat? {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("PPToolConfigurationChanged", object: self) }
    }
}