//
//  Constants.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit
import AudioToolbox

class Constants {
    
    let musicSubPath: String = "Assets/Sounds/";
    let fretTexture: SKTexture = SKTexture(imageNamed: "grey_fret.png");
    
    let textures: [Colour: [String: SKTexture]] = [
        Colour.Blue: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Blue]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Blue]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Blue]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Blue]!)],
        Colour.Green: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Green]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Green]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Green]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Green]!)],
        Colour.Yellow: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Yellow]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Yellow]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Yellow]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Yellow]!)],
        Colour.Red: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Red]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Red]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Red]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Red]!)],
        Colour.Purple: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Purple]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Purple]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Purple]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Purple]!)],
        Colour.Grey: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Grey]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Grey]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Grey]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Grey]!)],
        Colour.Brown: [
            "normal": SKTexture(imageNamed: Colour.normal[Colour.Brown]!),
            "hover": SKTexture(imageNamed: Colour.hover[Colour.Brown]!),
            "pressed": SKTexture(imageNamed: Colour.pressed[Colour.Brown]!),
            "long": SKTexture(imageNamed: Colour.long[Colour.Brown]!)]
    ];
    
    let middleIcons: [String: SKTexture] = [
        "pause": SKTexture(imageNamed: "pause.png"),
        "play": SKTexture(imageNamed: "play.png"),
        "replay": SKTexture(imageNamed: "replay.png"),
        "stop": SKTexture(imageNamed: "stop.png")
    ];
    
    let settings: [String: SKTexture] = [
        "settings": SKTexture(imageNamed: "settings.png"),
        "mute": SKTexture(imageNamed: "mute.png"),
        "unmute": SKTexture(imageNamed: "unmute.png"),
        "pause": SKTexture(imageNamed: "pause.png"),
        "play": SKTexture(imageNamed: "play.png")
    ];


    var wooshSound: SystemSoundID = 0;
    var applauseSound: SystemSoundID = 0;

    
    init() {
        let wooshURL = NSBundle.mainBundle().URLForResource(musicSubPath + "Woosh", withExtension: "mp3");
        var osStatus = AudioServicesCreateSystemSoundID(wooshURL, &wooshSound);
        
        let applauseURL = NSBundle.mainBundle().URLForResource(musicSubPath + "Applause", withExtension: "mp3");
        osStatus = AudioServicesCreateSystemSoundID(wooshURL, &applauseSound);
    }

}