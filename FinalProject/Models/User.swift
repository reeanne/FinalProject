//
//  User.swift
//  FinalProject
//
//  Created by Paulina Koch on 16/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {

    @NSManaged var username: String
    @NSManaged var levels: NSSet
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, username: String) -> User {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: moc) as! User
        newItem.username = username;
        
        return newItem
    }

}
