//
//  CollectionItem.swift
//  FinalProject
//
//  Created by Paulina Koch on 28/05/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import Cocoa



class CollectionItem: NSCollectionViewItem {

    
    @IBOutlet weak var star1: NSImageView!
    @IBOutlet weak var star2: NSImageView!
    @IBOutlet weak var star3: NSImageView!
    
    
    @IBOutlet weak var artwork: NSImageView!
    @IBOutlet weak var levelName: NSTextField!
    @IBOutlet weak var score: NSTextField!
    
    
    
    func showStars(number: Int) {
        if (number < 3) {
            star3.hidden = true;
        }
        if (number < 2) {
            star2.hidden = true;
        }
        if (number < 1) {
            star1.hidden = true;
        }
    }
    
    func showLevelName(title: String) {
        levelName.stringValue = title;
    }
    
    func showScore(passedScore: Int) {
        score.stringValue = passedScore.description;
    }
    
    func showArtwork(image: NSImage) {
        artwork.image = image;
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        var result: CollectionItem = super.copyWithZone(zone) as! CollectionItem;
        NSBundle.mainBundle().loadNibNamed("CollectionItem", owner: result, topLevelObjects: nil);
        return result;
    }
    
    
}