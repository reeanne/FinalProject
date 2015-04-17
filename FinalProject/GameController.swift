//
//  GameController.swift
//  FinalProject
//
//  Created by Paulina Koch on 17/04/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation


import Cocoa

class GameController: NSViewController {
    
    var user: UserObject! = nil;
    var level: LevelObject! = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        user = (NSApplication.sharedApplication().delegate as! AppDelegate).user;
        level = (NSApplication.sharedApplication().delegate as! AppDelegate).level;


    }

}
