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

class GameScene: SKScene, SKPhysicsContactDelegate {

    var audioplayer: AVAudioPlayer! = nil;
    var user: UserObject! = nil;
    var level: LevelObject! = nil;
    var height: CGFloat! = nil;
    var width: CGFloat! = nil;
    
    // Dictionary of all the textures.
    let textures: [Colour: [String: SKTexture]] = [
        Colour.Blue: [
                "normal" :SKTexture(imageNamed: Colour.normal[Colour.Blue]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Blue]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Blue]!)],
        Colour.Green: [
                "normal": SKTexture(imageNamed: Colour.normal[Colour.Green]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Green]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Green]!)],
        Colour.Yellow: [
                "normal": SKTexture(imageNamed: Colour.normal[Colour.Yellow]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Yellow]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Yellow]!)],
        Colour.Red: [
                "normal": SKTexture(imageNamed: Colour.normal[Colour.Red]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Red]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Red]!)],
        Colour.Purple: [
                "normal": SKTexture(imageNamed: Colour.normal[Colour.Purple]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Purple]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Purple]!)],
        Colour.Grey: [
                "normal": SKTexture(imageNamed: Colour.normal[Colour.Grey]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Grey]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Grey]!)],
        Colour.Brown: [
                "normal": SKTexture(imageNamed: Colour.normal[Colour.Brown]!),
                "hover": SKTexture(imageNamed: Colour.hover[Colour.Brown]!),
                "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Brown]!)]
    ];
    
    var buttons: [SKSpriteNode]! = nil;
    var _movePipesAndRemove: SKAction! = nil;
    var _pipes: SKNode = SKNode();
    var missedField: SKNode! = nil;
    
    var timeInterval: Double = 0;
    var appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    var lastPitchSeen: Int = 0;
    // The offset needed for the buttons to come up as they are sung.
    let offsetCurrent: Double = 2;
    let offsetPresspoint: Double = 0;
    //let offsetPresspoint: Double = 7;
    var scored: SKLabelNode! = nil;
    var totalScore: SKLabelNode! = nil;
    
    // Collision Categories.
    let noteCategory: UInt32 = 0x1 << 0;
    let missedCategory: UInt32 = 0x1 << 1;
    
    var limit = 4;
    
    var hits: Int = 0;
    var misses: Int = 0;
    var mistakes: Int = 0;
    let overallRatio: CGFloat = 8;
    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
    override func didMoveToView(view: SKView) {
        
        self.level = appDelegate.level;
        self.user = appDelegate.user;
        self.physicsWorld.contactDelegate = self

        
        audioplayer = AVAudioPlayer(contentsOfURL: level.melody.audioURL, error: nil);
        timeInterval = Double(audioplayer.duration) / Double(level.melody.pitch!.count);

       // createBackground();
        buttons = initialiseButtons();
        createPipes();
        scored = self.childNodeWithName("ScoreParent")?.childNodeWithName("Scored") as! SKLabelNode
        totalScore = self.childNodeWithName("ScoreParent")?.childNodeWithName("TotalScore") as! SKLabelNode

        
        // TODO: Fix quick Game.
        audioplayer.prepareToPlay();
        audioplayer.play();

        height = CGRectGetMidX(self.frame) *  3 / 4;
        width = CGRectGetMidY(self.frame) * 2 / 4;
        
        // Print it to the console
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
        var distanceToMove: CGFloat = self.frame.size.height + 2 * textures[Colour.Blue]!["normal"]!.size().height;
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
    
    func initialiseButtons() -> [SKSpriteNode] {
        var colour: Colour;
        var texture: SKTexture;
        var index: CGFloat;
        var button: SKSpriteNode;
        var result = [SKSpriteNode]();
        for i in 0...limit-1 {
            colour = Colour(rawValue: i)!;
            texture = textures[colour]!["hover"]!;
            index = CGFloat(i + 1);
            button = SKSpriteNode(texture: texture);
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
    
    override func keyDown(theEvent: NSEvent) {
        
        switch theEvent.keyCode {
            case 0:
                println("a");
                var colour = Colour(rawValue: 0);
                removeButtonPressed(colour!);
                buttons[0].texture = textures[colour!]!["pressed"]!;
            case 1:
                println("s");
                var colour = Colour(rawValue: 1);
                removeButtonPressed(colour!);
                buttons[1].texture = textures[colour!]!["pressed"]!;
            case 2:
                println("d");
                var colour = Colour(rawValue: 2);
                removeButtonPressed(colour!);
                buttons[2].texture = textures[colour!]!["pressed"]!;
            case 3:
                println("f");
                var colour = Colour(rawValue: 3);
                removeButtonPressed(colour!);
                buttons[3].texture = textures[colour!]!["pressed"]!;
            case 35:
                println("pause");
                pause(!self.paused);
            default:
                break;
        }
    }
    
    
    func removeButtonPressed(colour: Colour) {
        var points = self.nodesAtPoint(buttons[colour.rawValue].position);
        var spriteNode: SKSpriteNode;
        var texture: SKTexture = textures[colour]!["normal"]!;
        
        if (points.count > 1) {
            for point in points {
                if (point is SKSpriteNode) {
                    spriteNode = point as! SKSpriteNode;
                    if (spriteNode.texture?.hashValue == texture.hashValue) {
                        hits++;
                        point.removeFromParent();
                        updateBoard();
                        break;
                    }
                }
            }
        } else {
            mistakes++;
        }

    }
    
    func updateBoard() {
        scored.text = hits.description;
        totalScore.text = (misses + hits).description;
    }
    
    
    override func keyUp(theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 0:
            println("a");
            var colour = Colour(rawValue: 0);
            buttons[0].texture = textures[colour!]!["hover"]!;
        case 1:
            println("s");
            var colour = Colour(rawValue: 1);
            buttons[1].texture = textures[colour!]!["hover"]!;
        case 2:
            println("d");
            var colour = Colour(rawValue: 2);
            buttons[2].texture = textures[colour!]!["hover"]!;
        case 3:
            println("f");
            var colour = Colour(rawValue: 3);
            buttons[3].texture = textures[colour!]!["hover"]!;
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
        var texture = textures[colour!]!["normal"];
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
    
    func didBeginContact(contact: SKPhysicsContact) {
        println("Contact")
        var node: SKSpriteNode! = nil;
        if (contact.bodyA.node is SKSpriteNode && contact.bodyA.categoryBitMask == noteCategory &&
                contact.bodyB.categoryBitMask == missedCategory) {
                node = contact.bodyA.node as! SKSpriteNode;
                    
        } else if (contact.bodyB.node is SKSpriteNode && contact.bodyA.categoryBitMask == missedCategory &&
            contact.bodyB.categoryBitMask == noteCategory) {
                node = contact.bodyB.node as! SKSpriteNode;
        }
        println("changecolour")
        println(node.texture!.hashValue == textures[Colour.Grey]!["normal"]!.hashValue)
        node.texture = textures[Colour.Grey]!["normal"]!;
        misses++;
        updateBoard();
    
    }
    func gameOver() {
        let fadeOut = SKAction.sequence([SKAction.waitForDuration(3.0),
            SKAction.fadeOutWithDuration(3.0)])
        
        let welcomeReturn =  SKAction.runBlock({
            let transition = SKTransition.revealWithDirection(
                SKTransitionDirection.Down, duration: 1.0)
            let welcomeScene = GameScene(fileNamed: "GameScene")
            self.scene!.view?.presentScene(welcomeScene,
                transition: transition)
        })
        
        let sequence = SKAction.sequence([fadeOut, welcomeReturn])
        
        self.runAction(sequence)
    }
    
}
