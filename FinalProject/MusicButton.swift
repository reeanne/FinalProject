//
//  MusicButton.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit

class MusicButton {
    let id: Int;
    let colour: ButtonColour;
    var pressed = false;
    var node: SKSpriteNode;
    
    init(identification: Int, buttonColour: ButtonColour, location: CGPoint) {
        id = identification;
        colour = buttonColour;
        pressed = false;
        node = SKSpriteNode(imageNamed: buttonColour.idleURL());
        node.position = location;
    }
}
