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

class GameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate {

    var songPlayer: AVAudioPlayer! = nil;
    var user: UserObject! = nil;
    var level: LevelObject! = nil;

    var buttons: [SKSpriteNode]! = nil;
    var pressedButtons: [Bool]! = nil;
    
    var _movePipesAndRemove: SKAction! = nil;
    var _notes: SKNode = SKNode();
    var _frets: SKNode = SKNode();
    var missedField: SKNode! = nil;
    var constants: Constants = Constants();
    
    var timeInterval: Double = 0;
    var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    var lastButtonSeen: CGFloat = 0;
    
    // The offset needed for the buttons to come up as they are sung.
    let offsetCurrent: Double = 0;
    var offsetPresspoint: Double = 0;
    
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
    let noteCategory: UInt32 =  0b001;
    let missedCategory: UInt32 = 0b010;
    let longNoteCategory: UInt32 = 0b100;

    let overallRatio: CGFloat = 8;
    var limit = 4;
    
    // Score variables.
    var progressBar: ProgressBar! = nil;
    
    // Settings.
    var volume: Float = 0;
    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
    override func didMoveToView(view: SKView) {
        setupScene();
    }


    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
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
            pressedButtons[0] = false;
        case 1:
            var colour = Colour(rawValue: 1);
            buttons[1].texture = constants.textures[colour!]!["hover"]!;
            pressedButtons[1] = false;
        case 2:
            var colour = Colour(rawValue: 2);
            buttons[2].texture = constants.textures[colour!]!["hover"]!;
            pressedButtons[2] = false;
        case 3:
            var colour = Colour(rawValue: 3);
            buttons[3].texture = constants.textures[colour!]!["hover"]!;
            pressedButtons[3] = false;
        default:
            break;
        }
    }


    override func keyDown(theEvent: NSEvent) {
        
        switch theEvent.keyCode {
        case 0:
            var colour = Colour(rawValue: 0);
            removeButtonPressed(colour!);
            buttons[0].texture = constants.textures[colour!]!["pressed"]!;
        case 1:
            var colour = Colour(rawValue: 1);
            removeButtonPressed(colour!);
            buttons[1].texture = constants.textures[colour!]!["pressed"]!;
        case 2:
            var colour = Colour(rawValue: 2);
            removeButtonPressed(colour!);
            buttons[2].texture = constants.textures[colour!]!["pressed"]!;
        case 3:
            var colour = Colour(rawValue: 3);
            removeButtonPressed(colour!);
            buttons[3].texture = constants.textures[colour!]!["pressed"]!;
        case 12:
            if (self.paused){
                gameOver();
            }
        case 15:
            if (self.paused) {
                resetGame();
            }
        case 35:
            pause(!self.paused);
        default:
            break;
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var node: SKSpriteNode! = nil;
        var type: String;

        if (contact.bodyA.node is SKSpriteNode && contact.bodyA.categoryBitMask == noteCategory &&
            contact.bodyB.categoryBitMask == missedCategory) {
                node = contact.bodyA.node as! SKSpriteNode;
                type = "normal";
        } else if (contact.bodyB.node is SKSpriteNode && contact.bodyA.categoryBitMask == missedCategory &&
            contact.bodyB.categoryBitMask == noteCategory) {
                node = contact.bodyB.node as! SKSpriteNode;
                type = "normal";
        } else  if (contact.bodyA.node is SKSpriteNode && contact.bodyA.categoryBitMask == longNoteCategory &&
            contact.bodyB.categoryBitMask == missedCategory) {
                node = contact.bodyA.node as! SKSpriteNode;
                type = "long"
                if (removeLongNote(node)) {
                    return;
                }
        } else if (contact.bodyB.node is SKSpriteNode && contact.bodyA.categoryBitMask == missedCategory &&
            contact.bodyB.categoryBitMask == longNoteCategory) {
                node = contact.bodyB.node as! SKSpriteNode;
                type = "long"
                if (removeLongNote(node)) {
                    return;
                }
        } else {
            return;
        }
        node.texture = constants.textures[Colour.Grey]![type]!;
        if (type == "normal") {
            playWoosh();
        }
        node.zPosition = -1;
        progressBar.miss();
    }
    
    
    func playSong() {
        songPlayer.play();
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
    
    
    func spawnNotes() {
        if (songPlayer == nil) {
            return;
        }
        var index = Int((Double(songPlayer.currentTime) + offsetCurrent + offsetPresspoint) / timeInterval);
        if (index > level.melody.pitch!.count) {
            return;
        }
        var pitch: Int = level.melody.pitch![index];

        //if (abs(pitch - lastPitchSeen) > 50 && pitch > 0) {
        if (pitch > 0) {
            var (picture, x, zPosition) = determineColour(pitch);
            var note: SKSpriteNode = SKSpriteNode(texture: picture);
            note.position = CGPointMake(x, self.frame.size.height + picture.size().height);
            note.zPosition = zPosition;
            
            note.setScale(0.3);
            note.physicsBody = SKPhysicsBody(rectangleOfSize: note.size);
            note.physicsBody!.dynamic = false;
            note.physicsBody!.affectedByGravity = false;
            note.physicsBody!.usesPreciseCollisionDetection = true
            if (zPosition == 200) {         // It it is a full note.
                note.physicsBody!.categoryBitMask = noteCategory;
            } else if (zPosition == 100) {  // If it is a long note.
                note.physicsBody!.categoryBitMask = longNoteCategory;
            }
            note.physicsBody!.contactTestBitMask = missedCategory;
            missedField.physicsBody!.collisionBitMask = 0;
            
            note.runAction(_movePipesAndRemove);
            
            _notes.addChild(note);
            lastButtonSeen = x;
        } else {
            lastButtonSeen = 0;
        }

    }
    

    func createNotes() {
        var distanceToMove: CGFloat = self.frame.size.height + 2 * constants.textures[Colour.Blue]!["normal"]!.size().height;
        var movePipes: SKAction = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.01 * distanceToMove));
        //_pipeTexture1.filteringMode = SKTextureFilteringNearest;
        var removeNotes: SKAction = SKAction.removeFromParent();
        _movePipesAndRemove = SKAction.sequence([movePipes, removeNotes]);
        
        var spawn: SKAction = SKAction.runBlock(self.spawnNotes);
        var delay: SKAction = SKAction.waitForDuration((beats[1] - beats[0]) / 2);
        var spawnThenDelay: SKAction = SKAction.sequence([spawn, delay]);
        var spawnThenDelayForever: SKAction = SKAction.repeatActionForever(spawnThenDelay);
        self.runAction(spawnThenDelayForever, withKey: "notes");
        
        self.addChild(_notes);
        self.addChild(_frets)
    }

    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        songPlayer = nil;
        stopIssuing();
        showScore();
        println("Printing score");
    }



    func removeButtonPressed(colour: Colour) {
        var points = self.nodesAtPoint(buttons[colour.rawValue].position);
        var spriteNode: SKSpriteNode;
        var buttonTexture: SKTexture = constants.textures[colour]!["normal"]!;
        var lineTexture: SKTexture = constants.textures[colour]!["long"]!;
        
        if (points.count > 1) {
            for point in points {
                if (point is SKSpriteNode) {
                    spriteNode = point as! SKSpriteNode;
                    if (spriteNode.texture?.hashValue == buttonTexture.hashValue) {
                        progressBar.hit();
                        pressedButtons[colour.rawValue] = true;
                        point.removeFromParent();
                        return;
                    }
                    if (spriteNode.texture?.hashValue == lineTexture.hashValue) {
                        return;
                    }
                }
            }
            progressBar.mistake();
        }
    }


    func determineColour(pitch: Int) -> (SKTexture, CGFloat, CGFloat){
        var smallPitch = Int(pitch / 70) % limit;
        var colour = Colour(rawValue: smallPitch);
        var index: CGFloat = CGFloat(smallPitch + 1);
        var x: CGFloat = index * self.frame.size.width / overallRatio;
        var zPosition: CGFloat;
        var texture: SKTexture;
        if (x != lastButtonSeen) {
            texture = constants.textures[colour!]!["normal"]!;
            zPosition = 200;
        } else {
            texture = constants.textures[colour!]!["long"]!;
            zPosition = 100;
        }
        return (texture, index * self.frame.size.width / overallRatio, zPosition);
    }



    func setupScene() {
        self.level = appDelegate.level;
        self.user = appDelegate.user;
        self.physicsWorld.contactDelegate = self
        
        offsetPresspoint =  0.01 * Double(self.frame.size.height + 0.5 * constants.textures[Colour.Blue]!["normal"]!.size().height);
        
        beats = level.melody.beats;
        
        
        songPlayer = AVAudioPlayer(contentsOfURL: level.melody.audioURL, error: nil);
        songPlayer.delegate = self
        timeInterval = Double(songPlayer.duration) / Double(level.melody.pitch!.count);
        setupSprites();
        
        // TODO: Fix quick Game.
        println(NSTimeInterval(offsetPresspoint))
        songPlayer.prepareToPlay();
        var timer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(offsetPresspoint), target: self, selector: Selector("playSong"), userInfo: nil, repeats: false);
        
        beatsTimer = NSTimer.scheduledTimerWithTimeInterval(beats[2] - beats[0], target: self, selector: Selector("spawnFrets"), userInfo: nil, repeats: false);
    }

    

    func playerDidFinishPlaying(note: NSNotification) {
        showScore();
    }
    
    func setupSprites() {
        middleParent = self.childNodeWithName("MiddleParent")!;
        middleParent.hidden = true;
        muteButton = self.childNodeWithName("Mute") as! SKSpriteNode;
        settingsButton = self.childNodeWithName("Settings") as! SKSpriteNode;
        pauseButton = self.childNodeWithName("Pause") as! SKSpriteNode;
        
        progressBar = ProgressBar(progressBar: self.childNodeWithName("ScoreParent")?.childNodeWithName("ProgressBar") as! SKSpriteNode,
                                  scored: self.childNodeWithName("ScoreParent")?.childNodeWithName("Scored") as! SKLabelNode,
                                  totalScore: self.childNodeWithName("ScoreParent")?.childNodeWithName("TotalScore") as! SKLabelNode,
                                  multiplier: self.childNodeWithName("ScoreParent")?.childNodeWithName("Multiplier") as! SKLabelNode);
        
        showStars(0);
        buttons = initialiseButtons();
        pressedButtons = [Bool](count: limit, repeatedValue: false);
        createNotes();
        progressBar.updateProgressBar();
        
        setupMood();

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
            ])), withKey: "mood");
        self.addChild(sparkEmitter)
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
            button.zPosition = 300;
            button.setScale(0.3)
            button.position = CGPointMake(index * self.frame.size.width / overallRatio, self.frame.size.height / 6);
            self.addChild(button);
            result.append(button);
        }
        
        initialiseDevalidatingBody(result[0].size.height);
        return result;
    }

    
    func initialiseDevalidatingBody(buttonHeight: CGFloat) {
        
        missedField = SKNode();
        missedField.position = CGPointMake(0, self.frame.size.height / 6 - 1.1 * buttonHeight);
        missedField.physicsBody = SKPhysicsBody(
            rectangleOfSize: CGSize(width: self.frame.size.width, height: self.frame.size.height / 6 - buttonHeight));
        missedField.physicsBody!.dynamic = true;
        missedField.physicsBody!.affectedByGravity = false;
        missedField.physicsBody!.usesPreciseCollisionDetection = true
        missedField.physicsBody!.categoryBitMask = missedCategory;
        missedField.physicsBody!.collisionBitMask = 0;
        missedField.physicsBody!.pinned = true;
        self.addChild(missedField);

    }

    func showStars(number: Int) {
        var star: SKNode;
        var pauseImage = middleParent.childNodeWithName("MiddlePause") as! SKSpriteNode;

        for (var i = 1; i <= number; i++) {
             middleParent.childNodeWithName("Star" + i.description)!.hidden = false;
        }
        for (var i = number + 1; i <= 3; i++) {
             middleParent.childNodeWithName("Star" + i.description)!.hidden = true;
        }
        if (number == 0) {
            pauseImage.hidden = false;
        } else {
            pauseImage.hidden = true;
        }
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
        if (moodIndex < level.melody.arousal.count) {
            sparkEmitter.particleColor = SKColor(red: CGFloat(max(0, min(1, level.melody.arousal[moodIndex] + 0.2))),
                green: CGFloat(max(0, arc4random_uniform(1))),
                blue: CGFloat(max(0, (1 - min(1, (level.melody.valence[moodIndex] + 0.2))))), alpha: 0.7);
            println("here  " + level.melody.arousal[moodIndex].description + level.melody.valence[moodIndex].description);
            moodIndex++;
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

    
    /**
        Plays the sound effect for missed point.
    */
    func playWoosh() {
        if (volume == 0) {
            AudioServicesPlaySystemSound(constants.wooshSound);
        }
    }
    
    func resetGame() {
        self.removeAllActions();
        appDelegate.playGameWindow();
        
    }

    /**
        Detects whether the game is currently muted and unmutes it if so, mutes it otherwise.
    */
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


    /** 
        Removes the long note at the passed point if the user was in fact pressing the button when the note ends.
    */
    func removeLongNote(node: SKSpriteNode) -> Bool {
        var buttonIndex: Int;
        switch (node.texture!.hashValue) {
            case constants.textures[Colour(rawValue: 0)!]!["long"]!.hashValue:
                buttonIndex = 0;
            case constants.textures[Colour(rawValue: 1)!]!["long"]!.hashValue:
                buttonIndex = 1;
            case constants.textures[Colour(rawValue: 2)!]!["long"]!.hashValue:
                buttonIndex = 2;
            case constants.textures[Colour(rawValue: 3)!]!["long"]!.hashValue:
                buttonIndex = 3;
            default:
                return false;
        }
        if (pressedButtons[buttonIndex]) {
            node.removeFromParent();
            progressBar.hit();
            return true;
        }
        return false;
    }


    /**
    */
    func pause(pause: Bool) {
        
        self.paused = pause;
        if (pause) {
            pauseButton.texture = constants.settings["play"];
            if (songPlayer != nil) {
                songPlayer.pause();
                waitFor = beatsTimer.fireDate.timeIntervalSinceNow;
                beatsTimer.invalidate();
            }
        } else {
            pauseButton.texture = constants.settings["pause"];
            if (songPlayer != nil) {
                songPlayer.play();
                if (waitFor != nil) {
                    var fireNextBeat = NSTimer.scheduledTimerWithTimeInterval(waitFor, target: self, selector: Selector("spawnFrets"), userInfo:    nil, repeats: false);
                }
                waitFor = nil;
            }
            
        }
        middleParent.hidden = !pause;
    }

    /** 
        Triggered once the song is finished.
    */
    func showScore() {
        var stars = progressBar.finalCountdown();
        middleParent.hidden = false;
        stopIssuing();
        showStars(stars)
    }


    func stopIssuing() {
        self.removeActionForKey("mood");
        self.removeActionForKey("notes");
    }


    func gameOver() {
        pause(false);

        let fadeOut = SKAction.sequence([SKAction.waitForDuration(3.0),
            SKAction.fadeOutWithDuration(1.0)])
        
        let welcomeReturn =  SKAction.runBlock({
            let transition = SKTransition.revealWithDirection(
                SKTransitionDirection.Down, duration: 1.0)
            self.appDelegate.showMenu()
            if (self.songPlayer != nil) {
                self.songPlayer.stop();
                println ("removing");
                self.mute();
            }
        })
        
        let sequence = SKAction.sequence([fadeOut, welcomeReturn])
        
        self.runAction(sequence)
    }
    
}
