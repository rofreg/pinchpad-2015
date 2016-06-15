//
//  ToolConfig
//  PinchPad
//
//  Created by Ryan Laughlin on 3/5/15.
//
//

enum Tool: Int {
    case Brush
    case Marker
    case Pen
    case Eraser
    
    func toStrokeType() -> Stroke.Type{
        switch self{
        case .Brush: return BrushStroke.self
        case .Marker: return Stroke.self
        case .Pen: return PenStroke.self
        case .Eraser: return EraserStroke.self
        }
    }
}

class ToolConfig {
    // Set up a singleton instance
    static let sharedInstance = ToolConfig()
    
    // List our tool properties
    // Changing any of these properties should send out an NSNotification
    var tool = Tool.Brush {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self) }
    }
    var color = UIColor.blackColor() {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self) }
    }
    var width: CGFloat = 3.0 {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self) }
    }
    var isStylusConnected: Bool {
        get { return JotStylusManager.sharedInstance().isStylusConnected }
    }
}