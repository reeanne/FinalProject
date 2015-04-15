//
//  AppDelegate.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//


import Cocoa
import SpriteKit
import CoreData

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
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


    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /* Pick a size for the scene */
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill;
            
            self.skView!.presentScene(scene);

            hideCreateCharacterElements();
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            self.skView!.ignoresSiblingOrder = true;
            
            #if DEBUG
                self.skView!.showsFPS = true;
                self.skView!.showsNodeCount = true;
            #endif
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    func showBackButton() {
        backToMenuButton.hidden = false;
    }
    
    func hideBackButton() {
        backToMenuButton.hidden = true;
    }
    
    func showCreateCharacterElements() {
        showBackButton();
        submitCreateButton.hidden = false;
        usernameTextField.hidden = false;
    }
    
    func hideCreateCharacterElements() {
        hideBackButton();
        submitCreateButton.hidden = true;
        usernameTextField.hidden = true;
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
    
    
    /**
        This will allow a user to play a quick predefined level with no need to be a player
        or to preload some music.
    */
    @IBAction func quickGame(sender: AnyObject) {
        println("thispress");
    }
    
    /**
        Will allow the user to choose a player of the list of already created players.
    */
    @IBAction func chooseUser(sender: AnyObject) {
    }
    
    /**
        Will allow the user to create a new player.
    */
    @IBAction func createUser(sender: AnyObject) {
        hideMainMenuButtons();
        showCreateCharacterElements();
    }
    
    @IBAction func usernameEntered(sender: AnyObject) {
    }
    
    @IBAction func submitCreate(sender: AnyObject) {
        var username = usernameTextField.stringValue;
        var user = NSEntityDescription.insertNewObjectForEntityForName("User",
            inManagedObjectContext: managedObjectContext!) as! User;
    }

    @IBAction func backToMenuAction(sender: AnyObject) {
        hideCreateCharacterElements();
        showMainMenuButtons();
    }
    
    /**
        Allows the user to quit the game.
    */
    @IBAction func quitGame(sender: AnyObject) {
        self.saveContext();
        NSApplication.sharedApplication().terminate(self);
    }

    
    
    /** 
        Data Model code.
    */
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.xxxx.ProjectName" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask);
        return urls[urls.count-1] as! NSURL;
    }();
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!;
        return NSManagedObjectModel(contentsOfURL: modelURL)!;
    }();
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel);
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("FinalProject");
        var error: NSError? = nil;
        var failureReason = "There was an error creating or loading the application's saved data.";
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil;
            // Report any error we got.
            let dict = NSMutableDictionary();
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data";
            dict[NSLocalizedFailureReasonErrorKey] = failureReason;
            dict[NSUnderlyingErrorKey] = error;
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [NSObject : AnyObject]);
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)");
            abort();
        }
        
        return coordinator
    }();
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator;
        if coordinator == nil {
            return nil;
        }
        var managedObjectContext = NSManagedObjectContext();
        managedObjectContext.persistentStoreCoordinator = coordinator;
        return managedObjectContext;
    }();
    
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
}
