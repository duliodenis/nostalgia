//
//  MemoriesViewController.swift
//  Nostalgia
//
//  Created by Dulio Denis on 12/25/16.
//  Copyright © 2016 ddApps. All rights reserved.
//

import UIKit
import AVFoundation // Microphone Access
import Photos       // Photo Library Access
import Speech       // Speech Transcription

class MemoriesViewController: UICollectionViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPermissions()
    }
    
    
    func checkPermissions() {
        // check status for all three permissions
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        // aggregate all three status into a single boolean
        let authorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        
        // if we are missing one then show the first run screen
        if !authorized {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
                navigationController?.present(vc, animated: true, completion: nil)
            }
        }
    }

}
