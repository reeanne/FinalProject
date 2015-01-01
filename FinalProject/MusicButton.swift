//
//  MusicButton.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation

class MusicButton {
    let id: Int;
    let colour: ButtonColour;
    var pressed = false;
    
    init(identification: Int, buttonColour: ButtonColour) {
        id = identification;
        colour = buttonColour;
        pressed = false;
    }
}
