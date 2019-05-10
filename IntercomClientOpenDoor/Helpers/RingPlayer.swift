//
//  RingPlayer.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/10/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import Localize_Swift
import AVFoundation

class RingPlayer: NSObject {
    static let shared = RingPlayer()
    var player: AVAudioPlayer?
    func getDoorOpenSoundFile() -> String {
        if let langStr = Locale.current.languageCode {
            if(langStr.lowercased().contains("il") || langStr.lowercased().contains("iw") ||
                langStr.lowercased().contains("he")) {
                return "door_open_heb";
            } else if (langStr.lowercased().contains("ru")) {
                return "door_open_ru";
            } else if (langStr.lowercased().contains("en")) {
                return "door_open_en";
            } else {
                return "door_open_en";
            }
        }
        return "door_open_en";
    }
    
    func playDoorOpen(){
        guard let url = Bundle.main.url(forResource: self.getDoorOpenSoundFile(), withExtension: "mp3") else {
                print("play url is not available");
                return;
            }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }

    }
    func playDoorClose(){
        player?.stop()
    }
}
