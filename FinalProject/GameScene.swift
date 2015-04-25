//
//  GameScene.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/12/2014.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import AVFoundation
import AudioToolbox
import SpriteKit

class GameScene: SKScene {

    var audioplayer: AVAudioPlayer! = nil;
    var user: UserObject! = nil;
    var level: LevelObject! = nil;
    var height: CGFloat! = nil;
    var width: CGFloat! = nil;
    var _pipeTexture1: SKTexture = SKTexture(imageNamed: "blue_out");
    var _movePipesAndRemove: SKAction! = nil;
    var _pipes: SKNode = SKNode();

    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
    override func didMoveToView(view: SKView) {
        
        
        createBackground();
        //_pipeTexture1.filteringMode = SKTextureFilteringNearest;


        var distanceToMove: CGFloat = self.frame.size.height + 2 * _pipeTexture1.size().height;
        var movePipes: SKAction = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.01 * distanceToMove));

        var removePipes: SKAction = SKAction.removeFromParent();
        _movePipesAndRemove = SKAction.sequence([movePipes, removePipes]);

        var spawn: SKAction = SKAction.runBlock(self.spawnPipes);
        var delay: SKAction = SKAction.waitForDuration(2.0);
        var spawnThenDelay: SKAction = SKAction.sequence([spawn, delay]);
        var spawnThenDelayForever: SKAction = SKAction.repeatActionForever(spawnThenDelay);
        self.runAction(spawnThenDelayForever);
        
        self.addChild(_pipes);

        /* Setup your scene here */
        
        // Retreive the managedObjectContext from AppDelegate
        
        height = CGRectGetMidX(self.frame) *  3 / 4;
        width = CGRectGetMidY(self.frame) * 2 / 4;
        
        // Print it to the console
        println(managedObjectContext);
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        }
    
    func spawnPipes() {

        var pipePair: SKNode = SKNode();
        pipePair.position = CGPointMake(0, self.frame.size.height + _pipeTexture1.size().height);
        //pipePair.zPosition = -10;
        
        var x: CGFloat = self.frame.size.width / 3;

        var pipe1: SKSpriteNode = SKSpriteNode(texture:_pipeTexture1);
        pipe1.setScale(2);
        
        pipe1.position = CGPointMake(x, 0);
        pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipe1.size);
        pipe1.physicsBody!.dynamic = false;
        
        pipePair.addChild(pipe1);
        
        pipePair.runAction(_movePipesAndRemove);
        
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        
        _pipes.addChild(pipePair);
    }
    
    func createBackground() {
        // Create ground
        var groundTexture = SKTexture(imageNamed: "background_wave");
        //groundTexture.setFilteringMode(SKTextureFilteringMode.SKTextureFilteringNearest);
        var moveGroundSprite: SKAction = SKAction.moveByX(0, y: -self.frame.size.height * 2, duration: NSTimeInterval(0.02 * groundTexture.size().height));
        var resetGroundSprite: SKAction = SKAction.moveByX(0, y:self.frame.size.height * 2, duration: 0);
        var moveGroundSpritesForever: SKAction = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]));
        
        for(var i: CGFloat = 0; i < 2 + self.frame.size.height / (groundTexture.size().height * 2); ++i) {
            var sprite: SKSpriteNode = SKSpriteNode(texture: groundTexture);
            //sprite.setScale(0.5);
            sprite.position = CGPointMake(sprite.size.width / 2, CGFloat(i) * sprite.size.height);
            sprite.runAction(moveGroundSpritesForever);
            self.addChild(sprite);
        }

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
        let sprite = SKSpriteNode(imageNamed:"Spaceship");
        sprite.position = location;
        sprite.setScale(0.5);
        
        let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1);
        sprite.runAction(SKAction.repeatActionForever(action));
        
        self.addChild(sprite);
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    

      /**
        Starts off a predetermined level without the ability of choosing music.
    */
    func loadQuickGame(level: LevelObject) {
        
    }
    
    /**
        Function for playing the music file.
    */
    func startPlaying (audioURL: NSURL) {
        audioplayer = AVAudioPlayer(contentsOfURL: audioURL, error: nil);
        audioplayer.prepareToPlay();
        audioplayer.play();
    }
    
}
