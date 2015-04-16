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
    @NSManaged var pitch: String
    @NSManaged var level: Level
    @NSManaged var mood: Mood

}
