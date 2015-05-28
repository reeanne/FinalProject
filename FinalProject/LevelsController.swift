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


class LevelsController: NSViewController {
    
    var managedObjectContext: NSManagedObjectContext! = nil;
    
    var userData: User! = nil;
    var filePath: String! = nil;
    var appDelegate: AppDelegate! = nil;
    
    @IBOutlet var theView: NSVisualEffectView!
    @IBOutlet weak var collection: NSScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext;
        userData = getUser(appDelegate.user.username);
        var levelFiles = getLevelFiles(userData);
        var musicData: MusicEntry;
        for levelFile in levelFiles {
            musicData = getMetaDataForSong(levelFile)!;
        }

    }
    
    func getMetaDataForSong(fileURL: NSURL) -> MusicEntry? {
        
        var result = MusicEntry();
        var id3DataSize: UInt32 = 0;
        
        var audioFileID: AudioFileID = nil;
        
        var err = AudioFileOpenURL(fileURL, Int8(kAudioFileReadPermission), 0, &audioFileID)
    
        err = AudioFileGetPropertyInfo(audioFileID, UInt32(kAudioFilePropertyID3Tag), &id3DataSize, nil)
        if err != Int32(noErr) {
            NSLog("AudioFileGetPropertyInfo failed for id3 tag")
            return nil;
        }
        
        var dictionary: NSDictionary = NSDictionary()
        var piDataSize : UInt32 = UInt32(sizeof(NSDictionary))
        err = AudioFileGetProperty(audioFileID, UInt32(kAudioFilePropertyInfoDictionary), &piDataSize, &dictionary)
        println(dictionary.description);
        if err != Int32(noErr) {
            NSLog("AudioFileGetProperty failed for property info dictionary")
        }
        println(dictionary.debugDescription);
        var album: AnyObject? = dictionary[NSString(string: kAFInfoDictionary_Album)];
        var artist: AnyObject? = dictionary[NSString(string: kAFInfoDictionary_Artist)];
        var title: AnyObject? = dictionary[NSString(string: kAFInfoDictionary_Title)];
        
        if (album != nil) { result.album = album as! String }
        if (artist != nil) { result.artist = artist as! String }
        if (title != nil) { result.title = title as! String }
        
        return result;
        
    }

    
    /*
    func getMetaDataForSong(fileURL: NSURL) -> MusicEntry {
        
        var asset: AVURLAsset = AVURLAsset(URL:fileURL, options:nil);
        var musicEntry: MusicEntry = MusicEntry();
        for format in asset.availableMetadataFormats {
            println(format)
            for item in asset.metadataForFormat(format as! String) {
                println();
                println(item)
                var current = item as! AVMetadataItem;
                if (item.commonKey == "title") {
                    musicEntry.title = current.value() as! String;
                }
                if (item.commonKey == "artist") {
                     musicEntry.artist = current.value() as! String;
                }
                if (item.commonKey == "albumName") {
                     musicEntry.album = current.value() as! String;
                }
                if (item.commonKey == "artwork") {
                    var data: NSData = current.value() as! NSData;
                    musicEntry.artwork = NSImage(data: data);
                    
                }
            }
        }
        return musicEntry;
    }
*/
    
    func getArtwork() {
           }
    
    
    func initialiseGridView() {
        
    }
    /*
    func makeDeleteButtonForCell(cell: NSCollectionViewCellcell) -> CollectionViewCellButton {
        var button: CollectionViewCellButton  = CollectionViewCellButton(buttonWithType: NSButtonTypeCustom);
        var newImageSize: CGSize = CGSizeMake(cell.frame.size.width/2.5, cell.frame.size.height/2.5);
    
        var width: CGFloat = 100;
        var height: CGFloat = 100;
        var X: CGFloat = cell.frame.size.width - width;
        var Y: CGFloat = cell.frame.origin.y;
    
    button.frame = CGRectMake(X, Y, width, height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
    action:@selector(deleteCollectionViewCell:)
    forControlEvents:UIControlEventTouchUpInside];
    
    return button;
    

    }
    */
    /**
        Retrieves all the levels from the Core Data.
    */
    func getLevelFiles(owner: User?) -> [NSURL] {
        var levels: [NSURL] = [];
        let fetchRequest = NSFetchRequest(entityName: "Level")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        if ((owner) != nil) {
            let predicate = NSPredicate(format: "owner = %@", owner!);
            fetchRequest.predicate = predicate;
        }
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            for level in fetchResults {
                levels.append(NSURL(fileURLWithPath: level.melody.file)!);
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
