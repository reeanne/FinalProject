//
//  Melody.swift
//  FinalProject
//
//  Created by Paulina Koch on 01/01/2015.
//  Copyright (c) 2015 Paulina Koch. All rights reserved.
//

import Foundation
import AudioToolbox

class MelodyObject {
    
    var audioFile: AudioFileID;
    var mood: Mood?;
    var pitch: [Int]?;
    
    
    init(audioURL: CFURL) {
        audioFile = nil
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
}
