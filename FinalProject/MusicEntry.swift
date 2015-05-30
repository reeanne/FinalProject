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
    var score: Int = 0;
    var artwork: NSImage! = nil;
    
    init(levelName: String, artwork: NSImage, score: Int) {
        self.levelName = levelName;
        self.artwork = artwork;
        self.score = score;
    }
}
