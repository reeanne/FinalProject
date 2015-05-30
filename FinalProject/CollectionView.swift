//
//  CollectionView.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/05/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class CollectionView: NSCollectionView  {
    
    
    
    override func newItemForRepresentedObject(object: AnyObject!) -> NSCollectionViewItem!{
        
        var item: MusicEntry = object as! MusicEntry;
        var newItem: CollectionItem = super.newItemForRepresentedObject(object) as! CollectionItem;
        var view = newItem.view;
        
        println()
        println()
        println()
        println("sdfsfdsfs")
        println(object);
        println()
        println()
        println("view exposedBindings")
        println(view.exposedBindings);
        

        newItem.levelName.bind("stringValue", toObject: item, withKeyPath: "levelName", options: nil)
        newItem.score.bind("stringValue", toObject: object, withKeyPath: "score", options: nil)
//        view.bin
        return newItem;
    }
}