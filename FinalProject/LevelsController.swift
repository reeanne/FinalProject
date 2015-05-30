//
//  LevelsControllers.swift
//  FinalProject
//
//  Created by Paulina Koch on 27/05/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation


class LevelsController: NSViewController, NSCollectionViewDelegate {
    
    var managedObjectContext: NSManagedObjectContext! = nil;
    
    var userData: User! = nil;
    var filePath: String! = nil;
    var appDelegate: AppDelegate! = nil;
    var collArray: NSMutableArray! = nil;
    var collection: NSMutableArray! = nil;
    
    
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var theView: NSVisualEffectView!
    @IBOutlet weak var collectionView: NSCollectionView!
    

    
    override func awakeFromNib() {
        collection = NSMutableArray();
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext;
        userData = getUser(appDelegate.user.username);
        collArray = NSMutableArray();
        
        collectionView.delegate = self
        collectionView.minItemSize = NSSize(width: 150, height: 150);
        collectionView.maxItemSize = NSSize(width: 150, height: 150);
        
        var levelFiles = getLevelFiles(userData);
        var size: Int = 0;
        var musicEntry: MusicEntry;
        
        var sizeCol = NSMakeSize(150, 150)

        for (index, (name, url)) in enumerate(levelFiles) {
            musicEntry = MusicEntry(levelName: name, artwork: getAlbumArtworkInfo(url), score: 0)
            size = arrayController.arrangedObjects.count;
            arrayController.insertObject(musicEntry, atArrangedObjectIndex: size);
        }
    }
    

    func getAlbumArtworkInfo(fileURL: NSURL) -> NSImage {

        var asset: AVURLAsset = AVURLAsset(URL: fileURL, options:nil);
        var currentSongArtwork: NSImage = NSImage(byReferencingFile: "play.png")!;
        var artworks = AVMetadataItem.metadataItemsFromArray(asset.commonMetadata,
            withKey: AVMetadataCommonKeyArtwork, keySpace: AVMetadataKeySpaceCommon)
        
        for item in artworks {
            var subitem = item as! AVMetadataItem;
            if (item.keySpace == AVMetadataKeySpaceID3) {
                var d: NSData = subitem.value().copyWithZone(nil) as! NSData;
                currentSongArtwork = NSImage(data: d)!;
            } else if (item.keySpace == AVMetadataKeySpaceiTunes) {
                println("iTunes song - your album retrieval failed.")
            } else {
                currentSongArtwork = NSImage(byReferencingFile: "play.png")!
            }
        }
        return currentSongArtwork;
    }
    

    /**
        Retrieves all the levels from the Core Data.
    */
    func getLevelFiles(owner: User?) -> [String: NSURL] {
        var levels: [String: NSURL] = [String : NSURL]();
        let fetchRequest = NSFetchRequest(entityName: "Level")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        if ((owner) != nil) {
            let predicate = NSPredicate(format: "owner = %@", owner!);
            fetchRequest.predicate = predicate;
        }
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            for level in fetchResults {
                var url = NSURL(fileURLWithPath: level.melody.file);
                levels.updateValue(url!, forKey: level.name);
            }
        }
        return levels;
    }
    
    func getUser(name: String) -> User {
        let fetchRequest = NSFetchRequest(entityName: "User")
        let predicate = NSPredicate(format: "username = %@", name)
        fetchRequest.predicate = predicate;
        var result: User! = nil;
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [User] {
            result = fetchResults[0];
        }

        return result;
    }

}
