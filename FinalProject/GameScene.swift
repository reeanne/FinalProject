//
//  GameScene.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//

import AVFoundation
import AudioToolbox
import SpriteKit

class GameScene: SKScene {

    var audioplayer: AVAudioPlayer! = nil;
    var user: UserObject! = nil;
    
    let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    
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
     /*
        var path = openfiledlg("Open file",  message:"Open file");
        //        let audioURL = NSURL.fileURLWithPath("/Users/paulinakoch/Music/iTunes/iTunes Media/Music/Compilations/The Hobbit_ The Battle Of The Five Armies (Limited Deluxe)/2-21 The Last Goodbye.mp3");
        let audioURL = NSURL.fileURLWithPath(path);
        
        NSLog("Siabadabadu  \(path)")
        
        getPredominantMelody(audioURL!);
        var melody = Melody(audioURL: audioURL!)

        var locationRed = CGPoint(x:width / 2, y:height);
        var locationBlue = CGPoint(x:width * 3 / 2, y:height);
        var currentLevel = Level(levelName:"Level", locationList:[locationRed, locationBlue], melody: melody);
        for child in currentLevel.buttons {
            self.addChild(child.node);
        }
        if (audioURL != nil) {
            startPlaying(audioURL!);
        }
        //AudioFileClose(audioFile);
*/
        // Retreive the managedObjectContext from AppDelegate
        
        // Print it to the console
        println(managedObjectContext);
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
    
    func getPredominantMelody(audioURL: NSURL) {
        var task = NSTask();
        task.launchPath = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/essentia-master/build/src/examples/streaming_predominantmelody";
        task.arguments = [audioURL, "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/output.yaml"];
        task.launch();
        println("started");
        task.waitUntilExit();
        var status = task.terminationStatus;
        println("finished");
        if (status == 0) {
            NSLog("Task succeeded.");
        } else {
            NSLog("Task failed.");
        }
    }
    
    
    /**
        Opens a dialog window allowing the user to choose a file to open.
    */
    func openfiledlg (title: String, message: String) -> String {
        var myFiledialog: NSOpenPanel = NSOpenPanel();
        
        myFiledialog.prompt = "Open";
        myFiledialog.worksWhenModal = true;
        myFiledialog.allowsMultipleSelection = false;
        myFiledialog.canChooseDirectories = false;
        myFiledialog.resolvesAliases = true;
        myFiledialog.title = title;
        myFiledialog.message = message;
        myFiledialog.runModal();
        var chosenfile = myFiledialog.URL;
        if (chosenfile != nil) {
            var TheFile = chosenfile!.path!;
            return (TheFile);
        } else {
            return ("");
        }
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
