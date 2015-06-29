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
    
    var scene: GameScene!;
    var appDelegate: AppDelegate! = nil;
    
    @IBOutlet var skView: SKView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        load();
    }
    
    func load() {
        self.appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        
        scene = GameScene.unarchiveFromFile("GameScene") as? GameScene;
        
        if scene != nil {
            self.skView.allowsTransparency = true;
            for child in scene.children as! [SKNode] {
                if child is SKSpriteNode {
                    let sprite = child as! SKSpriteNode
                    sprite.texture?.preloadWithCompletionHandler({ })
                }
                for hisChild in child.children as! [SKNode] {
                    if hisChild is SKSpriteNode {
                        let sprite = hisChild as! SKSpriteNode
                        sprite.texture?.preloadWithCompletionHandler({ })
                    }
                }
            }
            scene.user = appDelegate.user;
            scene.level = appDelegate.level;
            scene.scaleMode = .AspectFill;
            self.skView!.presentScene(scene);
            self.skView!.ignoresSiblingOrder = true;
            
            #if DEBUG
                self.skView!.showsFPS = true;
                self.skView!.showsNodeCount = true;
            #endif
        }

    }

}
