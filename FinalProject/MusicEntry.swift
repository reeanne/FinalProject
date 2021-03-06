//
//  MusicEntry.swift
//  FinalProject
//
//  Created by Paulina Koch on 28/05/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import AppKit


class MusicEntry: NSObject {
    
    var levelName: String! = nil;
    var score: Int32 = 0;
    var stars: Int32 = 0
    var artwork: NSImage! = nil;
    
    var hidden1: Bool = false;
    var hidden2: Bool = false;
    var hidden3: Bool = false;
    
    init(levelName: String, artwork: NSImage, score: Int32, stars: Int32) {
        self.levelName = levelName;
        self.artwork = artwork;
        self.score = score;
        self.stars = max(0, min(3, stars));
        
        if (stars < 3) {
            hidden3 = true;
        }
        if (stars < 2) {
            hidden2 = true;
        }
        if (stars < 1) {
            hidden1 = true;
        }
        
    }
}
