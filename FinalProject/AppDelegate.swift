//
//  AppDelegate.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//


import Cocoa
import SpriteKit

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
    
    @IBOutlet weak var coverView: NSVisualEffectView!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var loadingProgressIndicator: NSProgressIndicator!

    @IBOutlet weak var quickGameButton: NSButton!
    @IBOutlet weak var chooseUserButton: NSButton!
    @IBOutlet weak var createUserButton: NSButton!
    @IBOutlet weak var quitGameButton: NSButton!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /* Pick a size for the scene */
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            self.skView!.presentScene(scene)
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            self.skView!.ignoresSiblingOrder = true
            
            #if DEBUG
            self.skView!.showsFPS = true
            self.skView!.showsNodeCount = true
            #endif
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    
    @IBAction func quickGame(sender: AnyObject) {
        println("thispress");
    }
    
    @IBAction func chooseUser(sender: AnyObject) {
    }
    
    @IBAction func createUser(sender: AnyObject) {
    }
    
    @IBAction func quitGame(sender: AnyObject) {
    }
}
