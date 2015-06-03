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
    @NSManaged var beats: [Float];
    @NSManaged var arousal: [Float];
    @NSManaged var valence: [Float];
    @NSManaged var level: Level;
    @NSManaged var labels: [String];
    @NSManaged var boundaries: [Float]
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, filePath: String, pitch: [Int], beats: [Float],
        arousal: [Float], valence: [Float], labels: [String], boundaries: [Float]) -> Melody {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("Melody", inManagedObjectContext: moc) as! Melody;
            newItem.file = filePath;
            newItem.pitch = pitch;
            newItem.beats = beats;
            newItem.arousal = arousal;
            newItem.valence = valence;
            newItem.labels = labels;
            newItem.boundaries = boundaries;
            return newItem
    }

}
