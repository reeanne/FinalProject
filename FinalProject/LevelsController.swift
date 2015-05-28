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
        
    }
    
    
    
    func getMetaDataForSong(fileURL: NSURL) -> MusicEntry {
        
        var asset: AVURLAsset = AVURLAsset(URL:fileURL, options:nil);
        var musicEntry: MusicEntry = MusicEntry();
        for format in asset.availableMetadataFormats {
            for item in asset.metadataForFormat(format as! String) {
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
    
    /*
    for (NSString *format in [assest availableMetadataFormats]) {
    for (AVMetadataItem *item in [assest metadataForFormat:format]) {
    if ([[item commonKey] isEqualToString:@"title"]) {
    musicItem.strSongTitle = (NSString *)[item value];
    }
    if ([[item commonKey] isEqualToString:@"artist"]) {
    musicItem.strArtistName = (NSString *)[item value];
    }
    if ([[item commonKey] isEqualToString:@"albumName"]) {
    musicItem.strAlbumName = (NSString *)[item value];
    }
    if ([[item commonKey] isEqualToString:@"artwork"]) {
    UIImage *img = nil;
    if ([item.keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
    img = [UIImage imageWithData:[item.value copyWithZone:nil]];
    }
    else { // if ([item.keySpace isEqualToString:AVMetadataKeySpaceID3]) {
    NSData *data = [(NSDictionary *)[item value] objectForKey:@"data"];
    img = [UIImage imageWithData:data]  ;
    }
    musicItem.imgArtwork = img;
    }
    }
    }
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
    func getLevels(owner: User?) -> [String] {
        var levels: [String] = [];
        let fetchRequest = NSFetchRequest(entityName: "Level")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        if ((owner) != nil) {
            let predicate = NSPredicate(format: "owner = %@", owner!);
            fetchRequest.predicate = predicate;
        }
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            for level in fetchResults {
                levels.append(level.name);
            }
        }
        return levels;
    }

}
