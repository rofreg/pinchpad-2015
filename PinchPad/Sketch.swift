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
    @NSManaged var imageData: NSData
    @NSManaged var rawService: Int16
    @NSManaged var syncError: Bool
    @NSManaged var syncStarted: NSDate?
}
