//
//  GameScene.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    
    override func didMoveToView(view: SKView) {
        let height = CGRectGetMidX(self.frame) *  3 / 4;
        let width = CGRectGetMidY(self.frame) * 2 / 4;

        /* Setup your scene here */
        /*
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        */
        var locationRed = CGPoint(x:width / 2, y:height);
        var locationBlue = CGPoint(x:width * 3 / 2, y:height);
        var currentLevel = Level(levelName:"Level", locationList:[locationRed, locationBlue]);
        for child in currentLevel.buttons {
            self.addChild(child.node);
        }
        
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        /*
        let location = theEvent.locationInNode(self)
        
        let sprite = SKSpriteNode(imageNamed:"Spaceship")
        sprite.position = location;
        sprite.setScale(0.5)
        
        let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
        sprite.runAction(SKAction.repeatActionForever(action))
        
        self.addChild(sprite)
        */
    }
    
    override func keyDown(theEvent: NSEvent) {
        var location :CGPoint = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        switch theEvent.keyCode {
            case 0:
                println("a");
                location = CGPoint(x:CGRectGetMidX(self.frame) / 2, y:CGRectGetMidY(self.frame));
            case 1:
                println("s");
                location = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
            case 2:
                println("d");
                location = CGPoint(x:CGRectGetMidX(self.frame) * 3 / 2, y:CGRectGetMidY(self.frame));
            case 3:
                println("f");
                location = CGPoint(x:CGRectGetMidX(self.frame) * 2, y:CGRectGetMidY(self.frame));
            default:
                break;
        }
        let sprite = SKSpriteNode(imageNamed:"Spaceship")
        sprite.position = location;
        sprite.setScale(0.5)
        
        let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
        sprite.runAction(SKAction.repeatActionForever(action))
        
        self.addChild(sprite)
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
        
}
