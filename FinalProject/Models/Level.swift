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

    @NSManaged var melody: Melody
    @NSManaged var owner: User

}
