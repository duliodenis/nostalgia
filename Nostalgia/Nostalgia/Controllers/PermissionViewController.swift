//
//  PermissionViewController.swift
//  Nostalgia
//
//  Created by Dulio Denis on 12/24/16.
//  Copyright © 2016 ddApps. All rights reserved.
//

import UIKit
import AVFoundation // Microphone Access
import Photos       // Photo Library Access
import Speech       // Speech Transcription

class PermissionViewController: UIViewController {

    @IBOutlet weak var helpLabel: UILabel!
    
    @IBAction func requestPermissions(_ sender: Any) {
        requestPhotoPermissions()
    }
    
    
    // MARK: - Individual Permissions Methods
    
    func requestPhotoPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self]
            authStatus in
            
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermissions()
                } else {
                    self.helpLabel.text = "Photos permission was declined; please enable it in Settings then tap Continue again."
                }
            }
            
        }
    }
    
    
    func requestRecordPermissions() {
         AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] allowed in
            
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermissions()
                } else {
                    self.helpLabel.text = "Recording permission was declined; please enable it in Settings then tap Continue again."
                }
            }
            
        }
    }
    
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcription permission was declined; please enable it in Settings then tap Continue again."
                }
            }
        }
    }
    
    
    func authorizationComplete() {
        dismiss(animated: true)
    }
    
}
