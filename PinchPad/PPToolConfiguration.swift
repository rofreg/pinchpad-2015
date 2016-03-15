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
    // TODO: there's a less verbose format for this in Swift 1.2
    class var sharedInstance: PPToolConfiguration {
        struct Static {
            static let instance: PPToolConfiguration = PPToolConfiguration()
        }
        return Static.instance
    }
    
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
        }
        get {
            // Eraser is automatically wider than the corresponding brush/marker
            if (self.tool == .Eraser){
                return self.privateWidth * 5
            } else {
                return self.privateWidth
            }
        }
    }
    private var privateWidth: CGFloat = 3.0 {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("PPToolConfigurationChanged", object: self) }
    }
    var pressure: CGFloat? {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("PPToolConfigurationChanged", object: self) }
    }
}