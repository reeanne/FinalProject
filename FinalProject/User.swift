//
//  User.swift
//  FinalProject
//
//  Created by Paulina Koch on 31/12/2014.
//  Copyright (c) 2014 Paulina Koch. All rights reserved.
//

import Foundation

class User {
    var username: String;
    var scores: [Int : Level]?;
    
    init(userName:String){
        username = userName;
        scores = Dictionary<Int, Level>();
    }
    
    
    
}