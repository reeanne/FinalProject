//
//  MusicButton.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit

enum Colour: Int {
    case Blue = 0, Green, Yellow, Red, Grey, Brown, Purple
    
    static var count: Int {
        var max: Int = 0
        while let _ = self(rawValue: ++max) {}
        return max
    }
    
    static let hover = [
        Blue: "hovered_blue",
        Green: "hovered_green",
        Yellow: "hovered_yellow",
        Red: "hovered_red",
        Grey: "hovered_grey",
        Brown: "hovered_brown",
        Purple: "hovered_purple"
    ];
    
    static let normal = [
        Blue: "normal_blue",
        Green: "normal_green",
        Yellow: "normal_yellow",
        Red: "normal_red",
        Grey: "normal_grey",
        Brown: "normal_brown",
        Purple: "normal_purple"
    ];
    
    static let pressed = [
        Blue: "pressed_blue",
        Green: "pressed_green",
        Yellow: "pressed_yellow",
        Red: "pressed_red",
        Grey: "pressed_grey",
        Brown: "pressed_brown",
        Purple: "pressed_purple"
    ];
}

class MusicButton {
    let id: Int;
    var pressed = false;
    var node: SKSpriteNode! = nil;
    
    init(identification: Int, location: CGPoint) {
        id = identification;
        pressed = false;

    }
}
