//
//  LevelCreationController.swift
//  FinalProject
//
//  Created by Paulina Koch on 19/06/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import CoreData
import AppKit
import Cocoa
import AVFoundation


class LevelCreationController: NSViewController {
    
    @IBOutlet weak var difficultyPopup: NSPopUpButton!
    @IBOutlet weak var colourChangesSwitch: NSSegmentedControl!
    @IBOutlet weak var uploadFileButton: NSButton!
    @IBOutlet weak var levelName: NSTextFieldCell!
    @IBOutlet weak var createSongButton: NSButton!
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var loadingProgressIndicator: NSProgressIndicator!
    
    var managedObjectContext: NSManagedObjectContext! = nil;
    var appDelegate: AppDelegate! = nil;
    var filePath: String! = "";



    override func viewDidLoad() {
        super.viewDidLoad();
        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext;

    }
    
    
    @IBAction func uploadButtonPressed(sender: AnyObject) {
        filePath = openfiledlg("Open file",  message:"Open file");
        if (filePath != "") {
            levelName.stringValue = getFileName(NSURL.fileURLWithPath(filePath)!);
        }
    }


    @IBAction func createSongPressed(sender: AnyObject) {
        if (levelName.stringValue != "" && isFilePlayable(NSURL(fileURLWithPath: filePath)!)) {
            loadingProgressIndicator.hidden = false;
            loadingProgressIndicator.startAnimation(self);
            chooseFile(filePath);
            loadingProgressIndicator.stopAnimation(self);
        } else {
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.addButtonWithTitle("OK")
            alert.informativeText = "Please make sure that the file you are trying to upload is a music file."
            var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
            alert.beginSheetModalForWindow (appDelegate.window, completionHandler: nil )
            
        }

    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        appDelegate.showMenu();
    }
    
    
    
    /**
        Checks if the file is of a correct type for the music analysis part to work.
    */
    func isFilePlayable(url: NSURL) -> Bool {
        
        // Try opening audiofile -> if it's playable it will open, if not, it will return error
        var audioFileID: AudioFileID = nil;
        
        let err = AudioFileOpenURL(url, Int8(kAudioFileReadPermission), 0, &audioFileID)
        
        if (err != noErr) {
            println("Couldn't open audio file...");
            return false;
        }
        
        AudioFileClose(audioFileID);
        return true;
    }
    
    /**
        Gets a file name from a path.
    */
    func getFileName(path: NSURL) -> String {
        return path.lastPathComponent!.stringByDeletingPathExtension;
    }
    
    
    
    /**
        A function called upon creation of a new level. It takes a file chosen by the user and generates a level out of it.
    */
    func chooseFile(path: String) {
        let audioURL = NSURL.fileURLWithPath(path);
        var difficulty = difficultyPopup.selectedItem!.title
        
        var melody = MelodyObject(audioURL: audioURL!, difficulty: difficulty);
        
        var currentLevel = LevelObject(levelName: levelName.stringValue, melody: melody, enhancedMood: colourChangesSwitch.selectedSegment == 1, difficulty: difficulty);
        
        var userData = getUser(appDelegate.user.username);

        if let moc = self.managedObjectContext {
            var melodyData = Melody.createInManagedObjectContext(moc, filePath: path, pitch: melody.pitch, beats: melody.beats, arousal: melody.arousal, valence: melody.valence, labels: melody.labels, boundaries: melody.boundaries);
            Level.createInManagedObjectContext(moc, name: currentLevel.name, user: userData, melody: melodyData, enhanced: currentLevel.enhancedMood, difficulty: difficultyPopup.selectedItem!.title);
        }
        
        appDelegate.level = currentLevel;
        appDelegate.playGameWindow();

    }

    /**
        Opens a dialog window allowing the user to choose a file to open.
    */
    func openfiledlg (title: String, message: String) -> String {
        var myFiledialog: NSOpenPanel = NSOpenPanel();
        
        myFiledialog.prompt = "Open";
        myFiledialog.worksWhenModal = true;
        myFiledialog.allowsMultipleSelection = false;
        myFiledialog.canChooseDirectories = false;
        myFiledialog.resolvesAliases = true;
        myFiledialog.title = title;
        myFiledialog.message = message;
        myFiledialog.runModal();
        var chosenfile = myFiledialog.URL;
        if (chosenfile != nil) {
            var TheFile = chosenfile!.path!;
            return (TheFile);
        } else {
            return ("");
        }
    }
    
    /**
        Retrieves a user with specified username from the Core Data.
    */
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


