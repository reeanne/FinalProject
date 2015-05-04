//
//  Melody.swift
//  FinalProject
//
//  Created by Paulina Koch on 16/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import CoreData

class Melody: NSManagedObject {

    @NSManaged var file: String
    @NSManaged var pitch: [Int];
    @NSManaged var beats: [Double]
    @NSManaged var level: Level
    @NSManaged var mood: Mood
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, filePath: String, pitch: [Int], beats: [Double]) -> Melody {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Melody", inManagedObjectContext: moc) as! Melody
        newItem.file = filePath;
        newItem.pitch = pitch;
        newItem.beats = beats;
        
        return newItem
    }

}
