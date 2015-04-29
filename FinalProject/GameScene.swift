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
    
    let textures: [Colour: SKTexture] = [
        Colour.Blue: SKTexture(imageNamed: Colour.normal[Colour.Blue]!),
        Colour.Green: SKTexture(imageNamed: Colour.normal[Colour.Green]!),
        Colour.Yellow: SKTexture(imageNamed: Colour.normal[Colour.Yellow]!),
        Colour.Red: SKTexture(imageNamed: Colour.normal[Colour.Red]!),
        Colour.Purple: SKTexture(imageNamed: Colour.normal[Colour.Purple]!),
        Colour.Grey: SKTexture(imageNamed: Colour.normal[Colour.Grey]!),
        Colour.Brown: SKTexture(imageNamed: Colour.normal[Colour.Brown]!)
    ];
    

    var _movePipesAndRemove: SKAction! = nil;
    var _pipes: SKNode = SKNode();
    var timeInterval: Double = 0;
    var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    var lastPitchSeen: Int = 0;
    // The offset needed for the buttons to come up as they are sung.
    let offsetCurrent: Double = 2;
    let offsetPresspoint: Double = 0;
    //let offsetPresspoint: Double = 7;
    
    var limit = 4;
    
    var hits: Int = 0;
    var misses: Int = 0;
    let overallRatio: CGFloat = 8;
    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
    override func didMoveToView(view: SKView) {
        
        self.level = appDelegate.level;
        self.user = appDelegate.user;
        
        audioplayer = AVAudioPlayer(contentsOfURL: level.melody.audioURL, error: nil);
        timeInterval = Double(audioplayer.duration) / Double(level.melody.pitch!.count);

       // createBackground();
        initialiseButtons();
        createPipes();
        drawLine();
        
        
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

      // if (abs(pitch - lastPitchSeen) > 50 && pitch > 0) {
        if (pitch > 0) {
            var (picture, x) = determineColour(pitch);
            var pipePair: SKNode = SKNode();
            pipePair.position = CGPointMake(0, self.frame.size.height + picture.size().height);
            //pipePair.zPosition = -10;

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
    
    func drawLine() {
        var line = SKShapeNode();
        var pathToDraw: CGMutablePathRef  = CGPathCreateMutable();
        CGPathMoveToPoint(pathToDraw, nil, 100.0, 100.0);
        CGPathAddLineToPoint(pathToDraw, nil, 50.0, 50.0);
        line.path = pathToDraw;
       // line.setStrokeColor(UIColor.redColor);
        addChild(line);
    }
    
    func createPipes() {
        var distanceToMove: CGFloat = self.frame.size.height + 2 * textures[Colour.Blue]!.size().height;
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
    
    func initialiseButtons() {
        var colour: Colour;
        var texture: SKTexture;
        var index: CGFloat;
        var button: SKSpriteNode;
        for i in 0...limit-1 {
            colour = Colour(rawValue: i)!;
            texture = SKTexture(imageNamed: Colour.hover[colour]!);
            index = CGFloat(i + 1);
            button = SKSpriteNode(texture: texture);
            button.setScale(0.3)
            button.position = CGPointMake(index * self.frame.size.width / overallRatio, self.frame.size.height / 6);
            self.addChild(button);
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
            case 35:
                println("pause");
                pause(!self.paused);
            default:
                break;
        }
    }
    
    func pause(pause: Bool) {
        self.paused = pause;
        self.view?.paused = pause;
        if (pause) {
            audioplayer.pause();
        } else {
            audioplayer.play();
        }

    }
    
    func determineColour(pitch: Int) -> (SKTexture, CGFloat){
        var smallPitch = Int(pitch / 70) % limit;
        var colour = Colour(rawValue: smallPitch);
        var texture = textures[colour!];
        var index: CGFloat = CGFloat(smallPitch + 1);
        return (texture!, index * self.frame.size.width / overallRatio);
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
