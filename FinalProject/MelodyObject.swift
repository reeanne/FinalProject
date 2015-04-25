//
//  Melody.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import AudioToolbox
import Yaml

class MelodyObject {
    
    var audioFile: AudioFileID;
    var mood: Mood?;
    var pitch: [Int]?;
    
    
    init(audioURL: NSURL) {
        audioFile = nil
        pitch = getPredominantMelody(audioURL);
        let status = AudioFileOpenURL(audioURL, Int8(kAudioFileReadPermission), AudioFileTypeID(kAudioFileMP3Type), &audioFile)
        println(status);
        printData();
    }
    
    
    func determineMood() -> Mood? {
        return nil;
    }
    /**
        Temporary method for printing data of the audiofile.
     */
    func printData() {
        var id3DataSize:UInt32 = 0
        var err = AudioFileGetPropertyInfo(audioFile, UInt32(kAudioFilePropertyID3Tag), &id3DataSize, nil)
        if err != Int32(noErr) {
            NSLog("AudioFileGetPropertyInfo faild for id3 tag")
        }
        
        var piDict:NSDictionary = NSDictionary()
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
            //NSLog(String(contentsOfFile: outputFile, encoding: NSUTF8StringEncoding, error: nil)!);
            NSLog("Come onnnnnn");
//            let output = Yaml.load(String(contentsOfFile: outputFile, encoding: NSUTF8StringEncoding, error: nil)!).value!;
            
            NSLog("Come onnnnnn");

      //      println(output[1]);
  //          var arrayYaml = output["tonal"]["predominant_melody"]["pitch"];
    //        println(arrayYaml);
            return [];
        } else {
            NSLog("Task failed.");
            return [];
        }
        
    }

}
