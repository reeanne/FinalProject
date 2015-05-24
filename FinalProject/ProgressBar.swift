//
//  ProgressBar.swift
//  FinalProject
//
//  Created by Paulina Koch on 24/05/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import SpriteKit



class ProgressBar {

    var progressBar: SKSpriteNode;
    var scored: SKLabelNode;
    var totalScore: SKLabelNode;
    
    var hits: Int = 0;
    var misses: Int = 0;
    var mistakes: Int = 0;
    var currentNumber: Float = 10;
    var maxCurrentNumber: Float = 20;
    var maxLength: Float = 0;
    var totalScoreNum: Int = 0;

    
    let progressBarTextures: [Int: SKTexture] = [
        0: SKTexture(imageNamed: "progress0.png"),
        10: SKTexture(imageNamed: "progress10.png"),
        20: SKTexture(imageNamed: "progress20.png"),
        30: SKTexture(imageNamed: "progress30.png"),
        40: SKTexture(imageNamed: "progress40.png"),
        50: SKTexture(imageNamed: "progress50.png"),
        60: SKTexture(imageNamed: "progress60.png"),
        70: SKTexture(imageNamed: "progress70.png"),
        80: SKTexture(imageNamed: "progress80.png"),
        90: SKTexture(imageNamed: "progress90.png"),
        100: SKTexture(imageNamed: "progress100.png"),
        200: SKTexture(imageNamed: "progressBlue.png")
    ];


    init(progressBar: SKSpriteNode, scored: SKLabelNode, totalScore: SKLabelNode) {
        self.progressBar = progressBar
        self.scored = scored;
        self.totalScore = totalScore;
    }
    
    func miss() {
        self.misses++;
        maxLength = 0;
        currentNumber--;
        currentNumber = max(currentNumber, 0);
    }
    
    func hit() {
        self.hits++;
        currentNumber++;
        if (currentNumber >= maxCurrentNumber) {
            maxLength++;
        }
        currentNumber = min(currentNumber, 20);
        totalScoreNum += Int(floor(maxLength / 20) + 1);
    }
    
    func mistake() {
        self.mistakes++;
        maxLength = 0;
        currentNumber--;
        currentNumber = max(currentNumber, 0);
    }
    
    func getMisses() -> Int {
        return misses;
    }
    
    func getMistakes() -> Int {
        return mistakes;
    }
    
    func getHits() -> Int {
        return hits;
    }
   
    func updateBoard() {
        scored.text = hits.description;
        totalScore.text = (misses + hits).description;
    }
    
    
    func updateProgressBar() {
        var ratio: Float = 10;
        var total: Int = Int(currentNumber);
        var result: Int;
        if (total < 0) {
            //    gameOver();
        } else if (maxLength >= 20) {
            progressBar.texture = progressBarTextures[200];
        } else {
            ratio = min(currentNumber * ratio / maxCurrentNumber, 100);
            println(ratio)
            result = Int(ceil(ratio)) * 10;
            total = max(0, result);
            println(total)
            progressBar.texture = progressBarTextures[total];
        }
        
    }
    
}
