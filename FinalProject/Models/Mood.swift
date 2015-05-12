//
//  Mood.swift
//  FinalProject
//
//  Created by Paulina Koch on 16/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import CoreData

class Mood: NSManagedObject {

    @NSManaged var valence: [Float];
    @NSManaged var arousal: [Float];
    @NSManaged var melodies: Melody

}
