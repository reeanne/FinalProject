//
//  HelpController.swift
//  FinalProject
//
//  Created by Paulina Koch on 29/06/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit
import CoreData
import AppKit
import Cocoa


class HelpController: NSViewController {
    
    @IBOutlet weak var textBox: NSScrollView!
    @IBOutlet weak var subtopic: NSPopUpButton!
    @IBOutlet weak var mainTopic: NSPopUpButton!
    @IBOutlet var text: NSTextView!
    
    var appDelegate: AppDelegate! = nil;
    var selected: [String: String]! = nil;
    
    let mainChoice: [String] = ["User", "Song", "Gameplay"];

    
    let userStrings: [String: String] = [
        "delete": "To delete a user, select the user you want to delete in the ``Choose a user`` menu and then click ``Delete''.",
        "add": "To create a new user, go to ``Create a user'', type in a new name and then click ``Create a user'' button.",
        "choose": "To choose the user you want to play with, in the main meny go to ``Choose the user'', select the user you want to play with and click ``Delete''."];
    let songStrings: [String: String] = [
        "delete": "To delete a song, go to ``Load a song'' in main menu, click on the cover of the song you want to remove and click ``Delete''.",
        "add": "To add a song, go to ``Upload song'' in the main menu, click on the ``Upload a file'' to select a music file you want to be used, choose the level difficulty (Easy/Medium/Hard), decide whether you want the mood changes to be visible more or less and rename your level however you like. Once you're done, click on ``Play the song''. After 2-3 min you're good to go!",
        "choose": "To play an already uploaded song, go to ``Load Song'', click on any song you would like and then press ``Play Song''."
    ];
    
    let gameHelp: [String: String] = [
        "buttons": "Press the buttons once they align with the notes coming down the screen. They keys are -- A, S, D, F.",
        "score": "Every time you ace the note, the bar on the right increases, otherwise it falls down. If you manage to keep in max for long enough, it will turn blue and you'll get double points!",
        "pause": "To pause, press P or the pause icon in the top right corner. You'll see a menu which allows you to resume, replay the game or go back to the menu.",
        "mute": "To mute the music, click on the mute button in the top right corner."
    ]

    

    override func viewDidLoad() {
        super.viewDidLoad();
        mainTopic.removeAllItems();
        subtopic.removeAllItems();
        var font: NSFont = NSFont(name: "Arial-BoldItalicMT", size: 17)!;
        text.font = font;
        mainTopic.addItemsWithTitles(mainChoice);
        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;

    }
    
    @IBAction func mainTopic(sender: AnyObject) {
        switch (mainTopic.selectedItem!.title) {
            case "User":
                subtopic.removeAllItems();
                subtopic.addItemsWithTitles(userStrings.keys.array);
            case "Song":
                subtopic.removeAllItems();
                subtopic.addItemsWithTitles(songStrings.keys.array);
            case "Gameplay":
                subtopic.removeAllItems();
                subtopic.addItemsWithTitles(gameHelp.keys.array);
            default:
                break;
        }
    }
    
    @IBAction func subtopic(sender: AnyObject) {
        switch (mainTopic.selectedItem!.title) {
        case "User":
            text.string = userStrings[subtopic.selectedItem!.title];
        case "Song":
            text.string = songStrings[subtopic.selectedItem!.title];
        case "Gameplay":
            text.string = gameHelp[subtopic.selectedItem!.title];
        default:
            break;
        }

    }
    
    @IBAction func menu(sender: AnyObject) {
        appDelegate.showMenu();
    }
    

    
}