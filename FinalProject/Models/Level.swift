//
//  Level.swift
//  FinalProject
//
//  Created by Paulina Koch on 16/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import CoreData

class Level: NSManagedObject {

    @NSManaged var name: String;
    @NSManaged var owner: User;
    @NSManaged var melody: Melody;
    @NSManaged var stars: Int32;
    @NSManaged var score: Int32
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, name: String, user: User, melody: Melody) -> Level {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Level", inManagedObjectContext: moc) as! Level
        newItem.name = name;
        newItem.melody = melody;
        newItem.owner = user;
        newItem.score = 0;
        newItem.stars = 0;
        return newItem
    }

}
