//
//  Sketch.swift
//  
//
//  Created by Ryan Laughlin on 4/24/15.
//
//

import UIKit
import CoreData
import ImageIO
import MobileCoreServices

class Sketch: NSManagedObject {
    @NSManaged var caption: String
    @NSManaged var createdAt: NSDate
    @NSManaged var duration: Double
    @NSManaged var imageData: NSData
    @NSManaged var rawService: Int16
    @NSManaged var syncError: Bool
    @NSManaged var syncStarted: NSDate?
    
    class func managedContext() -> NSManagedObjectContext{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.managedObjectContext!
    }
    
    
    // MARK: Animation
    
    class var animationFrames: NSArray{
        get {
            let fetchRequest = NSFetchRequest(entityName: "Sketch")
            fetchRequest.predicate = NSPredicate(format: "duration != 0")
            
            if let fetchResults = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil) as? [Sketch] {
                return fetchResults
            } else {
                return []
            }
        }
    }
    
    class var animationFrameCount: Int{
        get {
            return self.animationFrames.count
        }
    }

    class func assembleAnimatedGif() -> UIImage?{
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 100]]
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 2]]
        
        let documentsDirectory = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: documentsDirectory)?.URLByAppendingPathComponent("animated.gif")
        
        if let url = url {
            let frames = Sketch.animationFrames
            let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, frames.count, nil)
            CGImageDestinationSetProperties(destination, fileProperties)
            
            for frame in frames {
                var actualImage = UIImage(data: frame.imageData)
                CGImageDestinationAddImage(destination, actualImage!.CGImage, frameProperties)
            }
            
            if CGImageDestinationFinalize(destination) {
                // TODO: delete animation frames from CoreData
                return UIImage(data: NSData(contentsOfURL: url)!)
            } else {
                return nil
            }
        } else  {
            return nil
        }
    }
}
