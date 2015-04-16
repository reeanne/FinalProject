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

    @NSManaged var attribute: AnyObject
    @NSManaged var level: Level

}
