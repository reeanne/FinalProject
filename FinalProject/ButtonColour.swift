//
//  ButtonColour.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation

enum ButtonColour: Int {
    case Unknown = 0, Red, Blue, Yellow, Green;
    
    func pressedURL() -> NSString {
        switch self {
        case Red:
            return "red_in";
        case Green:
            return "green_in";
        case Yellow:
            return "yellow_in";
        case Blue:
            return "blue_in";
        default:
            return "";
        }
    }
    
    func idleURL() -> NSString {
        switch self {
        case Red:
            return "red_out";
        case Green:
            return "green_out";
        case Yellow:
            return "yellow_out";
        case Blue:
            return "blue_out";
        default:
            return "";
        }
    }
}