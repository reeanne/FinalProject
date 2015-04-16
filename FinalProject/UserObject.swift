//
//  User.swift
//  FinalProject
//
//  Created by Paulina Koch on 16/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import CoreData

class UserObject {
    
    var username: String;
    var scores: [Int64 : Int]?;
    var levels: [LevelObject];
    
    init(userName: String) {
        username = userName;
        scores = Dictionary<Int64, Int>();
        levels = [];
    }
    
    func addLevel(level: LevelObject) {
        levels.append(level);
        scores?.updateValue(0, forKey: level.id);
    }
    
    
}
