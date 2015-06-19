//
//  Level.swift
//  FinalProject
//
//  Created by Paulina Koch on 31/12/2014.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit


var CURRENT_ID: Int64 = 0;

class LevelObject {
    var id: Int64;
    var name: String;
    var melody: MelodyObject;
    var enhancedMood: Bool;
    var difficulty: String;
    
    init(levelName: String, melody: MelodyObject, enhancedMood: Bool, difficulty: String) {
        CURRENT_ID++;
        self.id = CURRENT_ID;
        self.name = levelName;
        self.melody = melody;
        self.enhancedMood = enhancedMood;
        self.difficulty = difficulty;
    }
}
