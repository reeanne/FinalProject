//
//  Constants.swift
//  FinalProject
//
//  Created by Paulina Koch on 30/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit


struct Constants {
    
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

}