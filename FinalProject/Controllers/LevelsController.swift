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
        var score: Int = 0;
        var stars: Int = 0;
        
        var sizeCol = NSMakeSize(150, 150)

        for (index, (name, (url, score, stars))) in enumerate(levelFiles) {
            musicEntry = MusicEntry(levelName: name, artwork: getAlbumArtworkInfo(url), score: score, stars: stars)
            size = arrayController.arrangedObjects.count;
            arrayController.insertObject(musicEntry, atArrangedObjectIndex: size);
        }
    }
    
    @IBAction func deleteLevel(sender: AnyObject) {
        var entry: MusicEntry? = getSelectedEntry();
        if (entry != nil) {
            deleteSelectedLevel(entry!.levelName);
        }
    }
    
    @IBAction func chooseLevel(sender: AnyObject) {
        var entry: MusicEntry? = getSelectedEntry();
        if (entry != nil) {
            playSelectedLevel(entry!);
        }
    }
    
    @IBAction func back(sender: AnyObject) {
        self.appDelegate.showMenu()
    }
    
    func getSelectedEntry() -> MusicEntry? {
        var cell: MusicEntry? = nil;
        var indexes = collectionView.selectionIndexes;
        if (indexes.count > 0) {
            cell = collectionView.content[indexes.firstIndex] as? MusicEntry;
        }
        return cell;
    }
    
    
    func playSelectedLevel(cell: MusicEntry) {
        var levelName = cell.levelName;
        println(levelName)
        if (levelName != nil) {
            var levelData = getLevel(levelName);
            var melodyData = levelData!.melody;
            var melodyObject: MelodyObject = MelodyObject(audioURL: NSURL(fileURLWithPath: melodyData.file)!, pitch: melodyData.pitch as [Int], beats: melodyData.beats as [Float], arousal: melodyData.arousal as [Float], valence: melodyData.valence as [Float], labels: melodyData.labels as [String], boundaries: melodyData.boundaries as [Float]);
            var levelObject: LevelObject = LevelObject(levelName: levelData!.name, melody: melodyObject);
            var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
            appDelegate.level = levelObject;
            println(melodyData.pitch);
            appDelegate.playGameWindow();
        }

    }
    
    /**
        Retrieves a level with specified name from the Core Data.
    */
    func getLevel(name: String) -> Level? {
        let fetchRequest = NSFetchRequest(entityName: "Level")
        println(name)
        let predicate = NSPredicate(format: "name = %@", name)
        fetchRequest.predicate = predicate;
        var result: Level! = nil;
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            println("akdhja")
            println(fetchResults.description);
            if (fetchResults.count > 0) {
                result = fetchResults[0];
            }
        }
        return result;
        
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
    func getLevelFiles(owner: User?) -> [String: (NSURL, Int32, Int32)] {
        var levels: [String: (NSURL, Int32, Int32)] = [String : (NSURL, Int32, Int32)]();
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
                var stars = level.stars;
                var score = level.score
                levels.updateValue((url!, score, stars) , forKey: level.name);
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
    
    func deleteSelectedLevel(name: String) {
        let fetchRequest = NSFetchRequest(entityName: "Level")
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            var levels = fetchResults;
            for lvl in levels {
                if (lvl.name == name) {
                    managedObjectContext?.deleteObject(lvl.melody);
                    managedObjectContext?.deleteObject(lvl);
                }
            }
        }
    }


}
