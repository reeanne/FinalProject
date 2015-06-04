//
//  Melody.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import AudioToolbox
import Foundation

enum MoodObject: Int {
    case Unknown = 0, Excited, Happy, Pleased, Relaxed, Peaceful, Calm, Sleepy, Bored, Sad, Nervous, Angry, Annoying;
}

class MelodyObject {
    
    var audioURL: NSURL;
    var pitch: [Int] = [];
    var beats: [Float] = [];
    var arousal: [Float] = [];
    var valence: [Float] = [];
    var labels: [String] = [];
    var boundaries: [Float] = [];
    
    init(audioURL: NSURL) {
        self.audioURL = audioURL;
        extractFeatures(audioURL);
    }
    
    init(audioURL: NSURL, pitch: [Int], beats: [Float], arousal: [Float], valence: [Float], labels: [String], boundaries: [Float]) {
        self.audioURL = audioURL;
        self.pitch = pitch;
        self.beats = beats;
        self.arousal = arousal
        self.valence = valence;
        self.labels = labels;
        self.boundaries = boundaries;
    }
    
    /**
        Temporary method for printing data of the audiofile.
     */
    
    func printData() {
        var audioFile: AudioFileID = nil;
        var id3DataSize: UInt32 = 0
        var err = AudioFileGetPropertyInfo(audioFile, UInt32(kAudioFilePropertyID3Tag), &id3DataSize, nil)
        if err != Int32(noErr) {
            NSLog("AudioFileGetPropertyInfo failed for id3 tag")
        }
        
        var piDict: NSDictionary = NSDictionary()
        var piDataSize : UInt32 = UInt32(sizeof(NSDictionary))
        err = AudioFileGetProperty(audioFile, UInt32(kAudioFilePropertyInfoDictionary), &piDataSize, &piDict)
        if err != Int32(noErr) {
            NSLog("AudioFileGetProperty failed for property info dictionary")
        }
        
        let albumString :NSString = piDict[NSString(string: kAFInfoDictionary_Album)] as! NSString
        let artistString : NSString = piDict[NSString(string: kAFInfoDictionary_Artist)] as! NSString
        let titleString : NSString = piDict[NSString(string:kAFInfoDictionary_Title)] as! NSString
        NSLog("\(albumString)   \(artistString)  \(titleString)")
        
    }
    
    /**
        Function running external process to retrieve all data for the new song to be generated.
    */
    func extractFeatures(audioURL: NSURL) {
        var task: NSTask = NSTask();
        var outputFile: String = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/output.json"
        var programPath: String = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/analyse_song.py";
        task.arguments = [programPath, audioURL, outputFile];
        task.launchPath = "/usr/local/bin/python";
        task.launch();
        task.waitUntilExit();
        var status = task.terminationStatus;
        
        if (status == 0) {
            NSLog("Task succeeded.");
            
            var inputStream: NSInputStream = NSInputStream(fileAtPath: outputFile)!;
            inputStream.open();
            let json = NSJSONSerialization.JSONObjectWithStream(inputStream, options: nil, error: nil) as! [String: AnyObject];
            
            // Parse mood.
            var mood = json["mood"] as! [[Float]];
            var arousalData = [Float](count:mood.count, repeatedValue: 0.0);
            var valenceData = [Float](count:mood.count, repeatedValue: 0.0);
            for (var i = 0; i < json.count; i++) {
                arousalData[i]  = mood[i][0];
                valenceData[i] = mood[i][1];
            }
            self.arousal = arousalData;
            self.valence = valenceData;
            
            // Parse beats.
            var beats = json["beats"] as! [Float];
            self.beats = beats;
            
            // Parse predominant.
            var predominant = json["pitch"] as! [Int];
            self.pitch = predominant;
            
            // Parse structure.
            var labels = json["labels"] as! [String];
            var boundaries = json["bounds"] as! [Float];
            self.labels = labels;
            self.boundaries = boundaries;
            
        } else {
            NSLog("Task failed.");
        }
    }

}