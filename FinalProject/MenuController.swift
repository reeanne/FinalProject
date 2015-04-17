//
//  ViewController.swift
//  kk
//
//  Created by Paulina Koch on 17/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Cocoa

class MenuController: NSViewController {
    
        
    @IBOutlet weak var mainQuickGameButton: NSButton!
    @IBOutlet weak var mainChooseUserButton: NSButton!
    @IBOutlet weak var mainCreateUserButton: NSButton!
    @IBOutlet weak var mainQuitGameButton: NSButton!
    
    @IBOutlet weak var backButton: NSButton!
    
    @IBOutlet weak var userCreateUserButton: NSButton!
    @IBOutlet weak var userUserNameField: NSTextField!
    
    @IBOutlet weak var loggedCreateLevelButton: NSButton!
    @IBOutlet weak var userLoadLevelButton: NSButton!
    
    @IBOutlet weak var levelSelectLevelPopup: NSPopUpButton!
    @IBOutlet weak var levelPlayLevelButton: NSButton!
    @IBOutlet weak var levelDeleteLevelButton: NSButton!
    
    @IBOutlet weak var userSelectUserPopup: NSPopUpButton!
    @IBOutlet weak var userChooseUserButton: NSButton!
    @IBOutlet weak var userDeleteUserButton: NSButton!
    
    var managedObjectContext: NSManagedObjectContext! = nil;
    var user: UserObject! = nil;
    var level: LevelObject! = nil;

    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideChooseLevelButtons();
        hideSelectUserButtons();
        showMainMenuButtons();
        managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext;
    }
    
    
    /**
        Button arrangements.
    */

    func showCreateCharacterElements() {
        backButton.hidden = false;
        userCreateUserButton.hidden = false;
        userUserNameField.hidden = false;
    }
    
    func hideCreateCharacterElements() {
        backButton.hidden = true;
        userCreateUserButton.hidden = true;
        userUserNameField.hidden = true;
    }
    
    func showSelectUserButtons() {
        backButton.hidden = false;
        userChooseUserButton.hidden = false;
        userDeleteUserButton.hidden = false;
        userSelectUserPopup.hidden = false;
    }
    
    func hideSelectUserButtons() {
        backButton.hidden = true;
        userChooseUserButton.hidden = true;
        userDeleteUserButton.hidden = true;
        userSelectUserPopup.hidden = true;
    }
    
    func hideMainMenuButtons() {
        mainQuickGameButton.hidden = true;
        mainChooseUserButton.hidden = true;
        mainCreateUserButton.hidden = true;
        mainQuitGameButton.hidden = true;
    }
    
    func showMainMenuButtons() {
        mainQuickGameButton.hidden = false;
        mainChooseUserButton.hidden = false;
        mainCreateUserButton.hidden = false;
        mainQuitGameButton.hidden = false;
    }
    
    func showLoggedUserButtons() {
        mainQuickGameButton.hidden = false;
        loggedCreateLevelButton.hidden = false;
        userLoadLevelButton.hidden = false;
        mainQuitGameButton.hidden = false;
    }
    
    func hideLoggedUserButtons() {
        mainQuickGameButton.hidden = true;
        loggedCreateLevelButton.hidden = true;
        userLoadLevelButton.hidden = true;
        mainQuitGameButton.hidden = true;
    }
    
    func showChooseLevelButtons() {
        levelSelectLevelPopup.hidden = false;
        levelPlayLevelButton.hidden = false;
        levelDeleteLevelButton.hidden = false;
        backButton.hidden = false;
        
    }
    
    func hideChooseLevelButtons() {
        levelSelectLevelPopup.hidden = true;
        levelPlayLevelButton.hidden = true;
        backButton.hidden = true;
        levelDeleteLevelButton.hidden = true;
    }

    
   
    /** 
        Event handlers.
    */
    
    /** Main Menu **/
    
    @IBAction func mainQuickGamePressed(sender: AnyObject) {
        hideMainMenuButtons();
        hideChooseLevelButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideMainMenuButtons();
        hideSelectUserButtons();
        (NSApplication.sharedApplication().delegate as! AppDelegate).playGameWindow();

    }
    
    @IBAction func mainChooseUserButtonPressed(sender: AnyObject) {
        var users: [String] = getUsers();
        userSelectUserPopup.addItemsWithTitles(users);
        hideChooseLevelButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideMainMenuButtons();
        showSelectUserButtons();

    }
    
    @IBAction func mainCreateUserButtonPressed(sender: AnyObject) {
        hideMainMenuButtons();
        hideChooseLevelButtons();
        hideLoggedUserButtons();
        hideSelectUserButtons();
        showCreateCharacterElements();

    }
    
    @IBAction func mainQuitGameButtonPressed(sender: AnyObject) {
        self.saveContext();
        NSApplication.sharedApplication().terminate(self);

    }
    
    /** Others **/
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        hideCreateCharacterElements();
        hideSelectUserButtons();
        hideChooseLevelButtons();
        if (user != nil) {
            hideMainMenuButtons();
            showLoggedUserButtons();
        } else {
            hideLoggedUserButtons();
            showMainMenuButtons();
        }

    }
    
    @IBAction func userCreateUserButtonPressed(sender: AnyObject) {
        var username = userUserNameField.stringValue;
        user = UserObject(userName: username);
        (NSApplication.sharedApplication().delegate as! AppDelegate).user = user;
        
        if let moc = self.managedObjectContext {
            User.createInManagedObjectContext(moc, username: username)
        }
        hideCreateCharacterElements();
        showLoggedUserButtons();

    }
 
    @IBAction func loggedCreateLevelButtonPressed(sender: AnyObject) {
    }
    
    @IBAction func userLoadLevelButtonPressed(sender: AnyObject) {
        var levels = getLevels();
        levelSelectLevelPopup.removeAllItems();
        levelSelectLevelPopup.addItemsWithTitles(levels);
        hideMainMenuButtons();
        hideCreateCharacterElements();
        hideLoggedUserButtons();
        hideSelectUserButtons();
        showChooseLevelButtons();
    }
    
    @IBAction func levelPlayLevelButtonPressed(sender: AnyObject) {
        var levelName = levelSelectLevelPopup.selectedItem?.description;

    }
    
    @IBAction func levelDeleteLevelButtonPressed(sender: AnyObject) {
        var name = levelSelectLevelPopup.selectedItem?.description;
        level = nil;
        (NSApplication.sharedApplication().delegate as! AppDelegate).level = nil;
        deleteLevel(name!);
        levelSelectLevelPopup.removeItemWithTitle(name!);
    }
    
    @IBAction func userChooseUserButtonPressed(sender: AnyObject) {
        var username = userSelectUserPopup.selectedItem?.title;
        user = UserObject(userName: username!);
        (NSApplication.sharedApplication().delegate as! AppDelegate).user = user;
        hideMainMenuButtons();
        hideChooseLevelButtons();
        hideSelectUserButtons();
        hideCreateCharacterElements();
        showLoggedUserButtons();
    }
    
    @IBAction func userDeleteUserButtonPressed(sender: AnyObject) {
        var username = userSelectUserPopup.selectedItem?.title;
        user = nil;
        (NSApplication.sharedApplication().delegate as! AppDelegate).user = nil;
        deleteUser(username!);
        userSelectUserPopup.removeItemWithTitle(username!);

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

