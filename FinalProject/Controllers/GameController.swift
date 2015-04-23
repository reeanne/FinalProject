//
//  GameController.swift
//  FinalProject
//
//  Created by Paulina Koch on 17/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit
import CoreData
import AppKit
import Cocoa

class GameController: NSViewController {
    
    
    var user: UserObject! = nil;
    var level: LevelObject! = nil;
    var scene: GameScene!;
    
    @IBOutlet var skView: SKView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        user = (NSApplication.sharedApplication().delegate as! AppDelegate).user;
        level = (NSApplication.sharedApplication().delegate as! AppDelegate).level;
        /* Pick a size for the scene */
        scene = GameScene.unarchiveFromFile("GameScene") as? GameScene;
        if scene != nil {
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill;
            self.skView!.presentScene(scene);



            // playGameWindow();
            /* Sprite Kit applies additional optimizations to improve rendering performance */
             self.skView!.ignoresSiblingOrder = true;
            
            #if DEBUG
                self.skView!.showsFPS = true;
                self.skView!.showsNodeCount = true;
            #endif
        }



    }

}
