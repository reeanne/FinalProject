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
    var blue: SKTexture = SKTexture(imageNamed: "normal_blue");
    var green: SKTexture = SKTexture(imageNamed: "normal_green");
    var yellow: SKTexture = SKTexture(imageNamed: "normal_yellow");
    var red: SKTexture = SKTexture(imageNamed: "normal_red");
    var purple: SKTexture = SKTexture(imageNamed: "normal_purple");
    var grey: SKTexture = SKTexture(imageNamed: "normal_grey");
    var brown: SKTexture = SKTexture(imageNamed: "normal_brown");


    var _movePipesAndRemove: SKAction! = nil;
    var _pipes: SKNode = SKNode();
    var timeInterval: Double = 0;
    var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    var lastPitchSeen: Int = 0;
    // The offset needed for the buttons to come up as they are sung.
    let offsetCurrent: Double = 2;
    let offsetPresspoint: Double = 0;
    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
    override func didMoveToView(view: SKView) {
        
        self.level = appDelegate.level;
        self.user = appDelegate.user;
        
        audioplayer = AVAudioPlayer(contentsOfURL: level.melody.audioURL, error: nil);
        timeInterval = Double(audioplayer.duration) / Double(level.melody.pitch!.count);

        createBackground();
        createPipes();
        
        // TODO: Fix quick Game.
        audioplayer.prepareToPlay();
        audioplayer.play();

        height = CGRectGetMidX(self.frame) *  3 / 4;
        width = CGRectGetMidY(self.frame) * 2 / 4;
        
        // Print it to the console
        println(managedObjectContext);
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        }
    
    func spawnPipes() {
        var index = Int((Double(audioplayer.currentTime) + offsetCurrent + offsetPresspoint) / timeInterval);
        var pitch: Int = level.melody.pitch![index];
        
        //println(audioplayer.currentTime);
        
       if (abs(pitch - lastPitchSeen) > 50 && pitch > 0) {
            var (picture, x) = determineColour(pitch);
            var pipePair: SKNode = SKNode();
            pipePair.position = CGPointMake(0, self.frame.size.height + picture.size().height);
            //pipePair.zPosition = -10;
            
            x = x *  self.frame.size.width / 8;

            var pipe1: SKSpriteNode = SKSpriteNode(texture: picture);
            pipe1.setScale(0.3);
            
            pipe1.position = CGPointMake(x, 0);
            pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipe1.size);
            pipe1.physicsBody!.dynamic = false;
            
            pipePair.addChild(pipe1);
            
            pipePair.runAction(_movePipesAndRemove);
            
            _pipes.addChild(pipePair);
        }
        lastPitchSeen = pitch;

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
    
    func createPipes() {
        var distanceToMove: CGFloat = self.frame.size.height + 2 * blue.size().height;
        var movePipes: SKAction = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.01 * distanceToMove));
        //_pipeTexture1.filteringMode = SKTextureFilteringNearest;
        var removePipes: SKAction = SKAction.removeFromParent();
        _movePipesAndRemove = SKAction.sequence([movePipes, removePipes]);
        
        var spawn: SKAction = SKAction.runBlock(self.spawnPipes);
        var delay: SKAction = SKAction.waitForDuration(0.1);
        var spawnThenDelay: SKAction = SKAction.sequence([spawn, delay]);
        var spawnThenDelayForever: SKAction = SKAction.repeatActionForever(spawnThenDelay);
        self.runAction(spawnThenDelayForever);
        
        self.addChild(_pipes);
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
    
    func determineColour(pitch: Int) -> (SKTexture, CGFloat){
        var smallPitch = Int(pitch / 50) % 8;
        println(pitch.description + "   " + smallPitch.description);
        switch(smallPitch) {
            case 0:
                return (blue, 1);
            case 1:
                return (green, 2);
            case 2:
                return (yellow, 3);
            case 3:
                return (red, 4)
            case 4:
                return (grey, 5)
            case 5:
                return (brown, 6)
            default:
                return (purple, 7)
        }
        
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
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
