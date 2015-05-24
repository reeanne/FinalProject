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
import Foundation

class GameScene: SKScene, SKPhysicsContactDelegate {

    var songPlayer: AVAudioPlayer! = nil;
    var user: UserObject! = nil;
    var level: LevelObject! = nil;

    var buttons: [SKSpriteNode]! = nil;
    var _movePipesAndRemove: SKAction! = nil;
    var _pipes: SKNode = SKNode();
    var _frets: SKNode = SKNode();
    var missedField: SKNode! = nil;
    var constants: Constants = Constants();
    
    var timeInterval: Double = 0;
    var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    var lastPitchSeen: Int = 0;
    
    // The offset needed for the buttons to come up as they are sung.
    let offsetCurrent: Double = 2;
    let offsetPresspoint: Double = 0;
    
    //let offsetPresspoint: Double = 7;
    var middleParent: SKNode! = nil;
    var settingsButton: SKSpriteNode! = nil;
    var muteButton: SKSpriteNode! = nil;
    var pauseButton: SKSpriteNode! = nil;
    
    // Beats.
    var beats: [Double]! = nil;
    var beatsTimer: NSTimer! = nil;
    var beatsIndex = 0;
    var waitFor: NSTimeInterval! = nil;
    
    // Mood.
    var moodIndex = 0;
    var sparkEmitter: SKEmitterNode! = nil;
    var moodXposition: Float = 1/3;
    var fourIntervals: Double = 0;
    var moodChangeTimer: NSTimer! = nil;
    
    // Collision Categories.
    let noteCategory: UInt32 = 0x1 << 0;
    let missedCategory: UInt32 = 0x1 << 1;
    
    let overallRatio: CGFloat = 8;
    var limit = 4;
    
    // Score variables.
    var progressBar: ProgressBar! = nil;
    
    // Settings.
    var volume: Float = 0;

    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
    override func didMoveToView(view: SKView) {
        
        self.level = appDelegate.level;
        self.user = appDelegate.user;
        self.physicsWorld.contactDelegate = self;

        beats = level.melody.beats;
        
        songPlayer = AVAudioPlayer(contentsOfURL: level.melody.audioURL, error: nil);
        timeInterval = Double(songPlayer.duration) / Double(level.melody.pitch!.count);
        
        setupSprites();

        
        // TODO: Fix quick Game.
        songPlayer.prepareToPlay();
        songPlayer.play();

        beatsTimer = NSTimer.scheduledTimerWithTimeInterval(beats[2] - beats[0], target: self, selector: Selector("spawnFrets"), userInfo: nil, repeats: false);
        
    }
    
    /* Called when a mouse click occurs */
    override func mouseDown(theEvent: NSEvent) {
        var nodes = nodesAtPoint(theEvent.locationInNode(self)) as! [SKNode]
        for node in nodes {
            if (node.name != nil && !node.hidden && !node.parent!.hidden) {
                switch node.name! {
                    case muteButton.name!:
                        mute();
                    case settingsButton.name!:
                        break;
                    case pauseButton.name!:
                        pause(!self.paused);
                    case "Resume":
                        pause(!self.paused);
                    case "Menu":
                        pause(false);
                        gameOver();
                    case "Replay":
                        // Replay.
                        pause(false)
                        println("Replay");
                        setupScene();
                        break;
                    default:
                        println(node.name)
                        break;

                }
            }
        }
    }
    
    override func keyUp(theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 0:
            var colour = Colour(rawValue: 0);
            buttons[0].texture = constants.textures[colour!]!["hover"]!;
        case 1:
            var colour = Colour(rawValue: 1);
            buttons[1].texture = constants.textures[colour!]!["hover"]!;
        case 2:
            var colour = Colour(rawValue: 2);
            buttons[2].texture = constants.textures[colour!]!["hover"]!;
        case 3:
            var colour = Colour(rawValue: 3);
            buttons[3].texture = constants.textures[colour!]!["hover"]!;
        default:
            break;
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        
        switch theEvent.keyCode {
        case 0:
            println("a");
            var colour = Colour(rawValue: 0);
            removeButtonPressed(colour!);
            buttons[0].texture = constants.textures[colour!]!["pressed"]!;
        case 1:
            println("s");
            var colour = Colour(rawValue: 1);
            removeButtonPressed(colour!);
            buttons[1].texture = constants.textures[colour!]!["pressed"]!;
        case 2:
            println("d");
            var colour = Colour(rawValue: 2);
            removeButtonPressed(colour!);
            buttons[2].texture = constants.textures[colour!]!["pressed"]!;
        case 3:
            println("f");
            var colour = Colour(rawValue: 3);
            removeButtonPressed(colour!);
            buttons[3].texture = constants.textures[colour!]!["pressed"]!;
        case 12:
            println("q");
            if (self.paused){
                pause(false);
                gameOver();
            }
        case 15:
            println("r");
            if (self.paused) {
                resetGame();
            }
        case 35:
            println("pause");
            pause(!self.paused);
        default:
            println(theEvent.keyCode);
            break;
        }
    }

    
    func spawnFrets() {
        if (beatsIndex < beats.count - 2) {
            var fret: SKSpriteNode = SKSpriteNode(texture: constants.fretTexture);
            var tempSize = constants.fretTexture.size();
            fret.position = CGPointMake(self.frame.size.width / overallRatio, self.frame.size.height + constants.fretTexture.size().height);
            fret.zPosition = 0;
            
            fret.runAction(_movePipesAndRemove);
            _frets.addChild(fret);
            beatsIndex += 2;
            beatsTimer = NSTimer.scheduledTimerWithTimeInterval(beats[beatsIndex]  - beats[beatsIndex-2], target: self, selector: Selector("spawnFrets"), userInfo: nil, repeats: false);
        }
    }
    
    func spawnPipes() {
        var index = Int((Double(songPlayer.currentTime) + offsetCurrent + offsetPresspoint) / timeInterval);
        if (index > level.melody.pitch!.count) {
            // Star Message & Score
        }
        var pitch: Int = level.melody.pitch![index];

        //if (abs(pitch - lastPitchSeen) > 50 && pitch > 0) {
        if (pitch > 0) {
            var (picture, x) = determineColour(pitch);
            var note: SKSpriteNode = SKSpriteNode(texture: picture);
            note.position = CGPointMake(x, self.frame.size.height + picture.size().height);
            //pipePair.zPosition = -10;
            
            note.setScale(0.3);
            
            note.physicsBody = SKPhysicsBody(rectangleOfSize: note.size);
            note.physicsBody!.dynamic = false;
            note.physicsBody!.affectedByGravity = false;
            note.physicsBody!.usesPreciseCollisionDetection = true
            note.physicsBody!.categoryBitMask = noteCategory;
            note.physicsBody!.contactTestBitMask = missedCategory;
            missedField.physicsBody!.collisionBitMask = 0;
            
            note.runAction(_movePipesAndRemove);
            
            _pipes.addChild(note);
        }
        lastPitchSeen = pitch;

    }
    
    func createBackground() {
        // Create ground
        var groundTexture = SKTexture(imageNamed: "background_wave");
        var moveGroundSprite: SKAction = SKAction.moveByX(0, y: -self.frame.size.height * 2, duration: NSTimeInterval(0.02 * groundTexture.size().height));
        var resetGroundSprite: SKAction = SKAction.moveByX(0, y: self.frame.size.height * 2, duration: 0);
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
        var distanceToMove: CGFloat = self.frame.size.height + 2 * constants.textures[Colour.Blue]!["normal"]!.size().height;
        var movePipes: SKAction = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.01 * distanceToMove));
        //_pipeTexture1.filteringMode = SKTextureFilteringNearest;
        var removePipes: SKAction = SKAction.removeFromParent();
        _movePipesAndRemove = SKAction.sequence([movePipes, removePipes]);
        
        var spawn: SKAction = SKAction.runBlock(self.spawnPipes);
        var delay: SKAction = SKAction.waitForDuration((beats[1] - beats[0]) / 2);
        var spawnThenDelay: SKAction = SKAction.sequence([spawn, delay]);
        var spawnThenDelayForever: SKAction = SKAction.repeatActionForever(spawnThenDelay);
        self.runAction(spawnThenDelayForever);
        
        self.addChild(_pipes);
        self.addChild(_frets)
    }
    
    func initialiseButtons() -> [SKSpriteNode] {
        var colour: Colour;
        var texture: SKTexture;
        var index: CGFloat;
        var button: SKSpriteNode;
        var result = [SKSpriteNode]();
        for i in 0...limit-1 {
            colour = Colour(rawValue: i)!;
            texture = constants.textures[colour]!["hover"]!;
            index = CGFloat(i + 1);
            button = SKSpriteNode(texture: texture);
            button.zPosition = 1;
            button.setScale(0.3)
            button.position = CGPointMake(index * self.frame.size.width / overallRatio, self.frame.size.height / 6);
            self.addChild(button);
            result.append(button)
        }
        
        missedField = SKNode();
        missedField.position = CGPointMake(0, self.frame.size.height / 6 - 1.25 * result[0].size.height);
        missedField.physicsBody = SKPhysicsBody(
            rectangleOfSize: CGSize(width: self.frame.size.width, height: self.frame.size.height / 6 - result[0].size.height));
        missedField.physicsBody!.dynamic = true;
        missedField.physicsBody!.affectedByGravity = false;
        missedField.physicsBody!.usesPreciseCollisionDetection = true
        missedField.physicsBody!.categoryBitMask = missedCategory;
        missedField.physicsBody!.collisionBitMask = 0;
        missedField.physicsBody!.pinned = true;
        self.addChild(missedField);

        return result;
    }
    
    func removeButtonPressed(colour: Colour) {
        var points = self.nodesAtPoint(buttons[colour.rawValue].position);
        var spriteNode: SKSpriteNode;
        var texture: SKTexture = constants.textures[colour]!["normal"]!;
        
        if (points.count > 1) {
            for point in points {
                if (point is SKSpriteNode) {
                    spriteNode = point as! SKSpriteNode;
                    if (spriteNode.texture?.hashValue == texture.hashValue) {
                        progressBar.hit();
                        point.removeFromParent();
                        progressBar.updateBoard();
                        progressBar.updateProgressBar();
                        return;
                    }
                }
            }
            progressBar.mistake();
            progressBar.updateProgressBar();
            progressBar.updateBoard();
        }
    }
   

    
    func pause(pause: Bool) {
        
        self.paused = pause;
        if (pause) {
            pauseButton.texture = constants.settings["play"];
            songPlayer.pause();
            waitFor = beatsTimer.fireDate.timeIntervalSinceNow;
            beatsTimer.invalidate();
        } else {
            pauseButton.texture = constants.settings["pause"];
            songPlayer.play();
            var fireNextBeat = NSTimer.scheduledTimerWithTimeInterval(waitFor, target: self, selector: Selector("spawnFrets"), userInfo: nil, repeats: false);
            waitFor = nil;

        }
        middleParent.hidden = !pause;

    }
    
    func determineColour(pitch: Int) -> (SKTexture, CGFloat){
        var smallPitch = Int(pitch / 70) % limit;
        var colour = Colour(rawValue: smallPitch);
        var texture = constants.textures[colour!]!["normal"];
        var index: CGFloat = CGFloat(smallPitch + 1);
        return (texture!, index * self.frame.size.width / overallRatio);
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func setupScene() {
        self.level = appDelegate.level;
        self.user = appDelegate.user;
        self.physicsWorld.contactDelegate = self
        
        beats = level.melody.beats;
        
        songPlayer = AVAudioPlayer(contentsOfURL: level.melody.audioURL, error: nil);
        timeInterval = Double(songPlayer.duration) / Double(level.melody.pitch!.count);
        setupSprites();
        
        // TODO: Fix quick Game.
        songPlayer.prepareToPlay();
        songPlayer.play();
        
        beatsTimer = NSTimer.scheduledTimerWithTimeInterval(beats[2] - beats[0], target: self, selector: Selector("spawnFrets"), userInfo: nil, repeats: false);

    }
    
    func setupSprites() {
        middleParent = self.childNodeWithName("MiddleParent")!;
        middleParent.hidden = true;
        muteButton = self.childNodeWithName("Mute") as! SKSpriteNode;
        settingsButton = self.childNodeWithName("Settings") as! SKSpriteNode;
        pauseButton = self.childNodeWithName("Pause") as! SKSpriteNode;
        
        progressBar = ProgressBar(progressBar: self.childNodeWithName("ScoreParent")?.childNodeWithName("ProgressBar") as! SKSpriteNode,
                                  scored: self.childNodeWithName("ScoreParent")?.childNodeWithName("Scored") as! SKLabelNode,
                                  totalScore: self.childNodeWithName("ScoreParent")?.childNodeWithName("TotalScore") as! SKLabelNode);
        
        // createBackground();
        showStars(0);
        buttons = initialiseButtons();
        createPipes();
        progressBar.updateProgressBar();
        
        setupMood();

    }
    
    func showStars(number: Int) {
        var star: SKNode;
        for (var i = 1; i <= number; i++) {
             middleParent.childNodeWithName("Star" + i.description)!.hidden = false;
        }
        for (var i = number + 1; i <= 3; i++) {
             middleParent.childNodeWithName("Star" + i.description)!.hidden = true;
        }
    }
    

    /**
        Function for playing the music file.
    */
    func startPlaying (audioURL: NSURL) {
        songPlayer = AVAudioPlayer(contentsOfURL: audioURL, error: nil);
        songPlayer.prepareToPlay();
        songPlayer.play();
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var node: SKSpriteNode! = nil;
        if (contact.bodyA.node is SKSpriteNode && contact.bodyA.categoryBitMask == noteCategory &&
                contact.bodyB.categoryBitMask == missedCategory) {
                node = contact.bodyA.node as! SKSpriteNode;
                    
        } else if (contact.bodyB.node is SKSpriteNode && contact.bodyA.categoryBitMask == missedCategory &&
            contact.bodyB.categoryBitMask == noteCategory) {
                node = contact.bodyB.node as! SKSpriteNode;
        } else {
            return;
        }
        node.texture = constants.textures[Colour.Grey]!["normal"]!; //
        playWoosh();
        node.zPosition = -1;
        progressBar.miss();
        progressBar.updateProgressBar();
    }
    
    
    func setupMood() {
        let sparkEmitterPath: String = NSBundle.mainBundle().pathForResource("FireFlies", ofType: "sks")!;
        sparkEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(sparkEmitterPath) as! SKEmitterNode;
        
        changeMood();
        sparkEmitter.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 - 200)
        sparkEmitter.name = "sparkEmmitter"
        sparkEmitter.zPosition = -1;
        sparkEmitter.targetNode = self;
        sparkEmitter.physicsBody = nil;
        
        moodChangeTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("changeMood"), userInfo: nil, repeats: true);
        fourIntervals = beats[beatsIndex + 4] - beats[beatsIndex];

        self.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(fourIntervals), SKAction.runBlock(moveSparkle)
        ])));
        self.addChild(sparkEmitter)
    }
    
    
    func moveSparkle() {
        
        if (beatsIndex + 4 <= beats.count) {
            fourIntervals = beats[beatsIndex + 4] - beats[beatsIndex];
            moodXposition *= -1;
            var x = CGFloat(0.5 + moodXposition) * self.frame.size.width;
            var y = CGFloat(arc4random_uniform((UInt32)(self.frame.size.height * 4 / 6))) + self.frame.size.height * 1 / 6;
            sparkEmitter.runAction(SKAction.sequence([SKAction.waitForDuration(fourIntervals), SKAction.moveTo(CGPoint(x: x, y: y), duration: fourIntervals)]));
        }
    }
    
    
    func changeMood() {
        sparkEmitter.particleColorSequence = nil;
        sparkEmitter.particleColor = SKColor(red: CGFloat(max(0, min(1, level.melody.arousal[moodIndex] + 0.2))),
            green: CGFloat(max(0, (1 - min(1, (level.melody.valence[moodIndex] + 0.2))))),
            blue: CGFloat(max(0, (1 - min(1, (level.melody.valence[moodIndex] + 0.2))))), alpha: 0.7);
        println("here  " + level.melody.arousal.description + level.melody.valence.description);
        moodIndex++;
    }

    
    func playWoosh() {
        if (volume == 0) {
            AudioServicesPlaySystemSound(constants.wooshSound);
        }
    }
    
    func resetGame() {
        self.removeAllActions();
        appDelegate.playGameWindow();
        
    }
    
    func mute() {
        if (songPlayer.volume == 0) {
            songPlayer.volume = volume;
            volume = 0;
            muteButton.texture = constants.settings["mute"];
        } else {
            volume = songPlayer.volume;
            songPlayer.volume = 0;
            muteButton.texture = constants.settings["unmute"];
        }
    }
    

    func gameOver() {
        let fadeOut = SKAction.sequence([SKAction.waitForDuration(3.0),
            SKAction.fadeOutWithDuration(1.0)])
        
        let welcomeReturn =  SKAction.runBlock({
            let transition = SKTransition.revealWithDirection(
                SKTransitionDirection.Down, duration: 1.0)
            self.appDelegate.showMenu()
        })
        
        let sequence = SKAction.sequence([fadeOut, welcomeReturn])
        
        self.runAction(sequence)
    }
    

    

    
}
