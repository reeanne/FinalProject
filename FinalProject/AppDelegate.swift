//
//  AppDelegate.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/12/2014.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//


import Cocoa
import SpriteKit
import CoreData

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!;
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData);
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene");
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene;
            archiver.finishDecoding();
            return scene;
        } else {
            return nil
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var coverView: NSVisualEffectView!;
    @IBOutlet weak var window: NSWindow!;
    @IBOutlet weak var skView: SKView!;
    @IBOutlet weak var loadingProgressIndicator: NSProgressIndicator!;
    
    @IBOutlet weak var quickGameButton: NSButton!;
    @IBOutlet weak var chooseUserButton: NSButton!;
    @IBOutlet weak var createUserButton: NSButton!;
    @IBOutlet weak var quitGameButton: NSButton!;
    
    @IBOutlet weak var submitCreateButton: NSButton!
    @IBOutlet weak var backToMenuButton: NSButton!
    @IBOutlet weak var usernameTextField: NSTextField!

    @IBOutlet weak var createLevelButton: NSButton!
    @IBOutlet weak var loadLevelButton: NSButton!
    
    @IBOutlet weak var levelSelectionPopup: NSPopUpButton!
    @IBOutlet weak var selectLevelButton: NSButton!
    @IBOutlet weak var deleteLevelSubmitButton: NSButton!
    
    @IBOutlet weak var userSelectionPopup: NSPopUpButton!
    @IBOutlet weak var chooseUserSubmitButton: NSButton!
    @IBOutlet weak var deleteUserSubmitButton: NSButton!
    
    
    var scene: GameScene!;
    var menuScene: MenuScene!;
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /* Pick a size for the scene */
        scene = GameScene.unarchiveFromFile("GameScene") as? GameScene;
        if scene != nil {
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill;
            
            self.skView!.presentScene(scene);
            hideCreateCharacterElements();
            hideLoggedUserButtons();
            hideChooseLevelButtons();
            hideSelectUserButtons();
            showMainMenuButtons();
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            self.skView!.ignoresSiblingOrder = true;
            
            #if DEBUG
                self.skView!.showsFPS = true;
                self.skView!.showsNodeCount = true;
            #endif
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true;
    }


    /**
        Button arrangements.
    */


    func showCreateCharacterElements() {
        backToMenuButton.hidden = false;
        submitCreateButton.hidden = false;
        usernameTextField.hidden = false;
    }

    func hideCreateCharacterElements() {
        backToMenuButton.hidden = true;
        submitCreateButton.hidden = true;
        usernameTextField.hidden = true;
    }

    func showSelectUserButtons() {
        backToMenuButton.hidden = false;
        chooseUserSubmitButton.hidden = false;
        deleteUserSubmitButton.hidden = false;
        userSelectionPopup.hidden = false;
    }

    func hideSelectUserButtons() {
        backToMenuButton.hidden = true;
        chooseUserSubmitButton.hidden = true;
        deleteUserSubmitButton.hidden = true;
        userSelectionPopup.hidden = true;
    }

    func hideMainMenuButtons() {
        quickGameButton.hidden = true;
        chooseUserButton.hidden = true;
        createUserButton.hidden = true;
        quitGameButton.hidden = true;
    }

    func showMainMenuButtons() {
        quickGameButton.hidden = false;
        chooseUserButton.hidden = false;
        createUserButton.hidden = false;
        quitGameButton.hidden = false;
    }

    func showLoggedUserButtons() {
        quickGameButton.hidden = false;
        createLevelButton.hidden = false;
        loadLevelButton.hidden = false;
        quitGameButton.hidden = false;
    }

    func hideLoggedUserButtons() {
        quickGameButton.hidden = true;
        createLevelButton.hidden = true;
        loadLevelButton.hidden = true;
        quitGameButton.hidden = true;
    }

    func showChooseLevelButtons() {
        levelSelectionPopup.hidden = false;
        selectLevelButton.hidden = false;
        deleteLevelSubmitButton.hidden = false;
        backToMenuButton.hidden = false;
        
    }

    func hideChooseLevelButtons() {
        levelSelectionPopup.hidden = true;
        selectLevelButton.hidden = true;
        backToMenuButton.hidden = true;
        deleteLevelSubmitButton.hidden = true;
    }



    /**
        Button listeners.
    */

    
    /****** Main Menu *******/

    @IBAction func quickGame(sender: AnyObject) {
        hideMainMenuButtons();
        hideChooseLevelButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideMainMenuButtons();
        hideSelectUserButtons();
    }

    @IBAction func chooseUser(sender: AnyObject) {
        var users: [String] = getUsers();
        userSelectionPopup.addItemsWithTitles(users);
        hideChooseLevelButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideMainMenuButtons();
        showSelectUserButtons();
    }
    
    @IBAction func createUser(sender: AnyObject) {
        hideMainMenuButtons();
        hideChooseLevelButtons();
        hideLoggedUserButtons();
        hideSelectUserButtons();
        showCreateCharacterElements();
    }
    
    @IBAction func quitGame(sender: AnyObject) {
        self.saveContext();
        NSApplication.sharedApplication().terminate(self);
    }


    /****** Choose User *******/
    
    @IBAction func chooseUserSelected(sender: AnyObject) {}
    
    @IBAction func chooseUserSubmitted(sender: AnyObject) {
        var username = userSelectionPopup.selectedItem?.title;
        scene.user = UserObject(userName: username!);
        hideMainMenuButtons();
        hideChooseLevelButtons();
        hideSelectUserButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
    }
    
    @IBAction func deleteUserSubmitted(sender: AnyObject) {
        var username = userSelectionPopup.selectedItem?.title;
        scene.user = nil;
        deleteUser(username!);
        userSelectionPopup.removeItemWithTitle(username!);
    }

    
    /****** Choose Level *******/
    
 
    @IBAction func selectLevelSubmit(sender: AnyObject) {
        var levelName = levelSelectionPopup.selectedItem?.description;
     }
        
    @IBAction func submitCreate(sender: AnyObject) {
        var username = usernameTextField.stringValue;
        scene.user = UserObject(userName: username);
        if let moc = self.managedObjectContext {
            User.createInManagedObjectContext(moc, username: username)
        }
        hideCreateCharacterElements();
        showLoggedUserButtons();
    }

    @IBAction func backToMenuAction(sender: AnyObject) {
        hideCreateCharacterElements();
        hideSelectUserButtons();
        hideChooseLevelButtons();
        if (scene.user != nil) {
            hideMainMenuButtons();
            showLoggedUserButtons();
        } else {
            hideLoggedUserButtons();
            showMainMenuButtons();
        }
    }
    
    @IBAction func deleteLevelSubmitted(sender: AnyObject) {
        var name = levelSelectionPopup.selectedItem?.description;
        scene.level = nil;
        deleteLevel(name!);
        userSelectionPopup.removeItemWithTitle(name!);
    }
    
    
    /****** Logged User ********/

    @IBAction func loadLevelPressed(sender: AnyObject) {
        var levels = getLevels();
        levelSelectionPopup.removeAllItems();
        levelSelectionPopup.addItemsWithTitles(levels);
        hideMainMenuButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideSelectUserButtons();
        showChooseLevelButtons();
    }
    
    @IBAction func createLevelPressed(sender: AnyObject) {
        
    }


    
    /****** Helper functions *******/
    
    func getLevels() -> [String] {
        var levels: [String] = [];
        let fetchRequest = NSFetchRequest(entityName: "Level")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            for level in fetchResults {
                levels.append(level.name);
            }
        }
        return levels;
    }
    
    func getUsers() -> [String] {
        var users: [String] = [];
        let fetchRequest = NSFetchRequest(entityName: "User")
        let sortDescriptor = NSSortDescriptor(key: "username", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [User] {
            println(fetchResults)
            for user in fetchResults {
                users.append(user.username);
            }
        }
        return users;
    }
    
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
    
    func deleteLevel(name: String) {
        let fetchRequest = NSFetchRequest(entityName: "Level")
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Level] {
            var levels = fetchResults;
            for lvl in levels {
                if (lvl.name == name) {
                    managedObjectContext?.deleteObject(lvl);
                }
            }
        }
        
    }
    
    
    /** 
        Data Model boilerplate code.
    */
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil;
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)");
                abort();
            }
        }
    }
    
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Paulina-Koch.FinalProject" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as! NSURL
        return appSupportURL.URLByAppendingPathComponent("Paulina-Koch.FinalProject")
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("FinalProject", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        // Make sure the application files directory is there
        let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey], error: &error)
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil, error: &error)
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("FinalProject.storedata")
            if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                coordinator = nil
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error!)
            return nil
        } else {
            return coordinator
        }
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSApplication.sharedApplication().presentError(error!)
            }
        }
    }
    
    
    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }
    
    
    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            if !moc.save(&error) {
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error!)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }

}
