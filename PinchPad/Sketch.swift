//
//  Sketch.swift
//  
//
//  Created by Ryan Laughlin on 4/24/15.
//
//

import Foundation
import CoreData

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
    
    class var animationFrameCount: Int{
        get {
            let fetchRequest = NSFetchRequest(entityName: "Sketch")
            fetchRequest.predicate = NSPredicate(format: "duration != 0")
            
            if let fetchResults = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil) as? [Sketch] {
                return fetchResults.count
            } else {
                return 0
            }
        }
    }
}
