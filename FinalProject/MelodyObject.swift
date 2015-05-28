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
    var pitch: [Int]?;
    var beats: [Double]?;
    var arousal: [Float] = [];
    var valence: [Float] = [];
    
    
    init(audioURL: NSURL) {
        self.audioURL = audioURL;
        self.pitch = getPredominantMelody(audioURL);
        self.beats = getBeats(audioURL);
        (self.arousal, self.valence) = getMood(audioURL);
    }
    
    init(audioURL: NSURL, pitch: [Int], beats: [Double], arousal: [Float], valence: [Float]) {
        self.audioURL = audioURL;
        self.pitch = pitch;
        self.beats = beats;
        self.arousal = arousal
        self.valence = valence;
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
    
    func getBeats(audioURL: NSURL) -> [Double] {
        var task: NSTask = NSTask();
        var outputFile: String = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/beat_output.json";
        
        // TODO: Change the paths to adjust to different users, not just mine...
        task.launchPath = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/essentia-master/build/src/examples/streaming_beattracker_multifeature_mirex2013";
        task.arguments = [audioURL, outputFile];
        task.launch();
        task.waitUntilExit();
        var status = task.terminationStatus;
        
        if (status == 0) {
            NSLog("Task succeeded.");
            var inputStream: NSInputStream = NSInputStream(fileAtPath: outputFile)!;
            inputStream.open();
            let json = NSJSONSerialization.JSONObjectWithStream(inputStream, options: nil, error: nil) as! [String: AnyObject];
            var rhythm = json["rhythm"] as! [String: AnyObject];
            var ticks = rhythm["ticks"] as! [Double];
            return ticks;
        } else {
            NSLog("Task failed.");
            return [];
        }
    }
    
    
    func getMood(audioURL: NSURL) -> ([Float],[Float]) {
        var task: NSTask = NSTask();
        var outputFile: String = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/gamepredictions.json";
        var programPath: String = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/extract_and_predict.py"
        
        // TODO: Change the paths to adjust to different users, not just mine...
        task.launchPath = "/usr/local/bin/python";
        task.arguments = [programPath, audioURL, "300"];
        task.launch();
        task.waitUntilExit();
        var status = task.terminationStatus;
        if (status == 0) {
            NSLog("Task succeeded.");
            
            var inputStream: NSInputStream = NSInputStream(fileAtPath: outputFile)!;
            inputStream.open();
            let json = NSJSONSerialization.JSONObjectWithStream(inputStream, options: nil, error: nil) as! [[Float]];
            var arousalData = [Float](count:json.count, repeatedValue: 0.0);
            var valenceData = [Float](count:json.count, repeatedValue: 0.0);
            for (var i = 0; i < json.count; i++) {
                arousalData[i]  = json[i][0];
                valenceData[i] = json[i][1];
            }
            println("asasasa", arousalData.description, "asasasasa", valenceData.description)
            return (arousalData, valenceData);
            //return ([], [])
        } else {
            NSLog("Task failed.");
            return ([], []);
        }

    }
    
    
    /**
        Calls an external executable determining a predominant melody.
    */
    func getPredominantMelody(audioURL: NSURL) -> [Int] {
        var task: NSTask = NSTask();
        var outputFile: String = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/output.json";
        
        // TODO: Change the paths to adjust to different users, not just mine...
        task.launchPath = "/Users/paulinakoch/Documents/Year 4/Project/FinalProject/essentia-master/build/src/examples/streaming_predominantmelody";
        task.arguments = [audioURL, outputFile];
        task.launch();
        task.waitUntilExit();
        var status = task.terminationStatus;
        
        if (status == 0) {
            NSLog("Task succeeded.");
            
            var inputStream: NSInputStream = NSInputStream(fileAtPath: outputFile)!;
            inputStream.open();
            let json = NSJSONSerialization.JSONObjectWithStream(inputStream, options: nil, error: nil) as! [String: AnyObject];
            var tonal = json["tonal"] as! [String: AnyObject];
            var predominant = tonal["predominant_melody"] as! [String: AnyObject];
            var pitch = predominant["pitch"] as! [Int];
            return pitch;
        } else {
            NSLog("Task failed.");
            return [];
        }
    }

}