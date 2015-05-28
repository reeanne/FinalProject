//
//  MusicEntry.swift
//  FinalProject
//
//  Created by Paulina Koch on 28/05/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import AppKit


class MusicEntry {
    
    var title: String! = nil;
    var album: String! = nil;
    var artist: String! = nil;
    var artwork: NSImage! = nil;
    
    
    init() {}
    
    init(title: String, album: String, artist: String,s artwork: NSImage) {
        self.title = title;
        self.album = album;
        self.artist = artist;
        self.artwork = artwork;

    }
}
