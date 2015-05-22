//
//  ViewController.swift
//  FinalProject
//
//  Created by Paulina Koch on 17/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation


class MenuController: NSViewController {
    
    @IBOutlet weak var mainQuickGameButton: NSButton!
    @IBOutlet weak var mainChooseUserButton: NSButton!
    @IBOutlet weak var mainCreateUserButton: NSButton!
    @IBOutlet weak var mainQuitGameButton: NSButton!
    
    @IBOutlet weak var backButton: NSButton!
    
    @IBOutlet weak var userCreateUserButton: NSButton!
    @IBOutlet weak var userUserNameField: NSTextField!
    
    @IBOutlet weak var loggedCreateLevelButton: NSButton!
    @IBOutlet weak var loggedLoadLevelButton: NSButton!

    @IBOutlet weak var levelSelectLevelPopup: NSPopUpButton!
    @IBOutlet weak var levelPlayLevelButton: NSButton!
    @IBOutlet weak var levelDeleteLevelButton: NSButton!
    
    @IBOutlet weak var userSelectUserPopup: NSPopUpButton!
    @IBOutlet weak var userChooseUserButton: NSButton!
    @IBOutlet weak var userDeleteUserButton: NSButton!
    
    @IBOutlet weak var newLevelUploadFile: NSButton!
    @IBOutlet weak var newLevelFilePath: NSTextField!
    @IBOutlet weak var newLevelCreateLevelButton: NSButton!
    
    @IBOutlet weak var loadingProgressIndicator: NSProgressIndicator!
    
    var player: AVAudioPlayer = AVAudioPlayer();
    var managedObjectContext: NSManagedObjectContext! = nil;
    var user: UserObject! = nil;
    var level: LevelObject! = nil;
    var userData: User! = nil;
    var filePath: String! = nil;


    override func viewDidLoad() {
        super.viewDidLoad()
        loadingProgressIndicator.hidden = true;
        showCreateCharacterElements(false);
        showLoggedUserButtons(false);
        showChooseLevelButtons(false);
        showSelectUserButtons(false);
        showLevelLoadButtons(false);
        showMainMenuButtons(true);
        managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext;
    }



    /********* Event handlers. ********/
    
    /** Main Menu **/
    
    @IBAction func mainQuickGamePressed(sender: AnyObject) {
        showMainMenuButtons(false);
        showChooseLevelButtons(false);
        showCreateCharacterElements(false);
        showLoggedUserButtons(false);
        showLevelLoadButtons(false);
        showSelectUserButtons(false);
        (NSApplication.sharedApplication().delegate as! AppDelegate).playGameWindow();
    }

    @IBAction func mainChooseUserButtonPressed(sender: AnyObject) {
        var users: [String] = getUsers();
        userSelectUserPopup.addItemsWithTitles(users);
        showChooseLevelButtons(false);
        showCreateCharacterElements(false);
        showLoggedUserButtons(false);
        showMainMenuButtons(false);
        showLevelLoadButtons(false);
        showSelectUserButtons(true);
    }
    
    @IBAction func mainCreateUserButtonPressed(sender: AnyObject) {
        showMainMenuButtons(false);
        showChooseLevelButtons(false);
        showLoggedUserButtons(false);
        showSelectUserButtons(false);
        showLevelLoadButtons(false);
        showCreateCharacterElements(true);
    }
   
    @IBAction func mainQuitGameButtonPressed(sender: AnyObject) {
        self.saveContext();
        NSApplication.sharedApplication().terminate(self);
    }
    
    /** Create User **/
    
    @IBAction func userCreateUserButtonPressed(sender: AnyObject) {
        var username = userUserNameField.stringValue;
        user = UserObject(userName: username);
        (NSApplication.sharedApplication().delegate as! AppDelegate).user = user;
        
        if let moc = self.managedObjectContext {
            userData = User.createInManagedObjectContext(moc, username: username)
        }
        showCreateCharacterElements(false);
        showLevelLoadButtons(false);
        showMainMenuButtons(false);
        showChooseLevelButtons(false);
        showSelectUserButtons(false);
        showLoggedUserButtons(true);
    }
    
    /** Logged user main menu **/
    
    @IBAction func loggedCreateLevelButtonPressed(sender: AnyObject) {
        showMainMenuButtons(false);
        showCreateCharacterElements(false);
        showLoggedUserButtons(false);
        showSelectUserButtons(false);
        showChooseLevelButtons(false);
        showLevelLoadButtons(true);

    }
    
    @IBAction func loggedLoadLevelButtonPressed(sender: AnyObject) {
        if (userData == nil) {
            userData = getUser(user.username);
        }
        var levels: [String] = getLevels(userData);
        levelSelectLevelPopup.addItemsWithTitles(levels);
        showMainMenuButtons(false);
        showCreateCharacterElements(false);
        showLoggedUserButtons(false);
        showSelectUserButtons(false);
        showLevelLoadButtons(false);
        showChooseLevelButtons(true);
    }
    
    /** Choose Level **/
    
    @IBAction func levelPlayLevelButtonPressed(sender: AnyObject) {
        var levelName = levelSelectLevelPopup.selectedItem?.title;
        if (levelName != nil) {
            var levelData = getLevel(levelName!);
            var melodyData = levelData!.melody;
            var melodyObject: MelodyObject = MelodyObject(audioURL: NSURL(fileURLWithPath: melodyData.file)!, pitch: melodyData.pitch as [Int], beats: melodyData.beats as [Double], arousal: melodyData.arousal as [Float], valence: melodyData.valence as [Float]);
            var levelObject: LevelObject = LevelObject(levelName: levelData!.name, melody: melodyObject);
            var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
            appDelegate.level = levelObject;
            println(melodyData.pitch);
            appDelegate.playGameWindow();
        }
    }
   
    
    @IBAction func levelDeleteLevelButtonPressed(sender: AnyObject) {
        var name = levelSelectLevelPopup.selectedItem?.title;
        level = nil;
        (NSApplication.sharedApplication().delegate as! AppDelegate).level = nil;
        deleteLevel(name!);
        levelSelectLevelPopup.removeItemWithTitle(name!);
    }
   
    /** Choose user **/
    
    @IBAction func userChooseUserButtonPressed(sender: AnyObject) {
        var username = userSelectUserPopup.selectedItem?.title;
        if (username != nil) {
            var userData :User = getUser(username!);
            user = UserObject(userName: userData.username);
            (NSApplication.sharedApplication().delegate as! AppDelegate).user = user;
            showMainMenuButtons(false);
            showChooseLevelButtons(false);
            showSelectUserButtons(false);
            showCreateCharacterElements(false);
            showLoggedUserButtons(true);
        }
    }
 
    @IBAction func userDeleteUserButtonPressed(sender: AnyObject) {
        var username = userSelectUserPopup.selectedItem?.title;
        user = nil;
        (NSApplication.sharedApplication().delegate as! AppDelegate).user = nil;
        deleteUser(username!);
        userSelectUserPopup.removeItemWithTitle(username!);
    }
    
    /** New level **/
    
    @IBAction func newLevelUoadLevelPressed(sender: AnyObject) {
        filePath = openfiledlg("Open file",  message:"Open file");
        newLevelFilePath.stringValue = getFileName(NSURL.fileURLWithPath(filePath)!);
    }
    
    @IBAction func newLevelCreateLevelSubmit(sender: AnyObject) {
        if (newLevelFilePath.stringValue != "" && isFilePlayable(NSURL(fileURLWithPath: filePath)!)) {
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
    
    @IBAction func newLevelFilePathFieldPressed(sender: AnyObject) {
        // Do nothing.
    }
    
    /** Universal **/
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        showCreateCharacterElements(false);
        showSelectUserButtons(false);
        showChooseLevelButtons(false);
        showLevelLoadButtons(false);
        if (user != nil) {
            showMainMenuButtons(false);
            showLoggedUserButtons(true);
        } else {
            showLoggedUserButtons(false);
            showMainMenuButtons(true);
        }
    }


    
    /****** Helper functions *******/
    
    /**
        Gets a file name from a path.
    */
    func getFileName(path: NSURL) -> String {
        return path.lastPathComponent!.stringByDeletingPathExtension;
    }
    
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

    /**
        Retrieves all the users from the Core Data.
    */
    func getUsers() -> [String] {
        var users: [String] = [];
        let fetchRequest = NSFetchRequest(entityName: "User")
        let sortDescriptor = NSSortDescriptor(key: "username", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [User] {
            for user in fetchResults {
                users.append(user.username);
            }
        }
        return users;
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
        Removes a user with specified username from the Core Data.
    */
    func deleteUser(username: String) {
        let fetchRequest = NSFetchRequest(entityName: "User")
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [User] {
            var users = fetchResults;
            for usr in users {
                if (usr.username == username) {
                    managedObjectContext?.deleteObject(usr);
                }
            }
        }
    }
    
    /**
        Removes a level with specified name from the Core Data.
    */
    func deleteLevel(name: String) {
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
    
    /**
        A function making sure all the data saved in the context is saved in the Core Data.
    */
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil;
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)");
                abort();
            }
        }
    }
    
    /**
        A function called upon creation of a new level. It takes a file chosen by the user and generates a level out of it.
    */
    func chooseFile(path: String) {
        let audioURL = NSURL.fileURLWithPath(path);
        
        var melody = MelodyObject(audioURL: audioURL!)
        var currentLevel = LevelObject(levelName: newLevelFilePath.stringValue, melody: melody);
        
        var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        userData = getUser(user.username);
        
        if let moc = self.managedObjectContext {
            var melodyData = Melody.createInManagedObjectContext(moc, filePath: path, pitch: melody.pitch!, beats: melody.beats!, arousal: melody.arousal, valence: melody.valence);
            Level.createInManagedObjectContext(moc, name: currentLevel.name, user: userData, melody: melodyData);
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

    
    /******** Button arrangements. ********/
    
    func showCreateCharacterElements(value: Bool) {
        backButton.hidden = !value;
        userCreateUserButton.hidden = !value;
        userUserNameField.hidden = !value;
    }
    
    func showSelectUserButtons(value: Bool) {
        backButton.hidden = !value;
        userChooseUserButton.hidden = !value;
        userDeleteUserButton.hidden = !value;
        userSelectUserPopup.hidden = !value;
    }
    
    
    func showMainMenuButtons(value: Bool) {
        mainQuickGameButton.hidden = !value;
        mainChooseUserButton.hidden = !value;
        mainCreateUserButton.hidden = !value;
        mainQuitGameButton.hidden = !value;
    }
    
    func showLoggedUserButtons(value: Bool) {
        mainQuickGameButton.hidden = !value;
        loggedCreateLevelButton.hidden = !value;
        loggedLoadLevelButton.hidden = !value;
        mainQuitGameButton.hidden = !value;
    }
    
    func showChooseLevelButtons(value: Bool) {
        levelSelectLevelPopup.hidden = !value;
        levelPlayLevelButton.hidden = !value;
        levelDeleteLevelButton.hidden = !value;
        backButton.hidden = !value;
    }
    
    func showLevelLoadButtons(value: Bool) {
        newLevelFilePath.hidden = !value;
        newLevelUploadFile.hidden = !value;
        newLevelCreateLevelButton.hidden = !value;
        backButton.hidden = !value;
    }
    
    

}

