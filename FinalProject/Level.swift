//
//  Level.swift
//  FinalProject
//
//  Created by Paulina Koch on 31/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//

import Foundation

enum Mood: Int {
    case Unknown = 0, Excited, Happy, Pleased, Relaxed, Peaceful, Calm, Sleepy, Bored, Sad, Nervous, Angry, Annoying;
}

class Level {
    var name: String;
    var mood: Mood?;
    var melody: Melody?;
    
    init(levelName:String) {
        name = levelName;
    }
    
    func determineMood() {
        
    }
}
