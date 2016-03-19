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
    var tool: Tool = Tool.Brush {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self) }
    }
    var color: UIColor = UIColor.blackColor() {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self) }
    }
    var width: CGFloat {
        set {
            self.privateWidth = newValue
            NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self)
        }
        get {
            // Eraser is automatically wider than the corresponding brush/marker
            return self.privateWidth * (self.tool == .Eraser ? 5 : 1)
        }
    }
    private var privateWidth: CGFloat = 3.0
    var pressure: CGFloat? {
        didSet { NSNotificationCenter.defaultCenter().postNotificationName("ToolConfigChanged", object: self) }
    }
}