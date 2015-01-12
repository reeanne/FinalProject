//
//  Level.swift
//  FinalProject
//
//  Created by Paulina Koch on 31/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit


enum Mood: Int {
    case Unknown = 0, Excited, Happy, Pleased, Relaxed, Peaceful, Calm, Sleepy, Bored, Sad, Nervous, Angry, Annoying;
}

class Level {
    var name: String;
    var mood: Mood?;
    var melody: Melody;
    var buttons: [MusicButton];
    
    init(levelName:String, locationList:[CGPoint], melody: Melody) {
        self.name = levelName;
        self.melody = melody;
        var initialButtons: [MusicButton] = []
        for (var i = 0; i < locationList.count; i++) {
            var a = i+1;
            initialButtons.append(MusicButton(identification: i, buttonColour:ButtonColour(rawValue: (i+1))!,
                location: locationList[i]))
        }
        self.buttons = initialButtons;
    }
    
    func determineMood() {
        
    }
}
