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
    
    // array of URLs for the memories
    var memories = [URL]()
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMemories()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPermissions()
    }
    
    
    // MARK: - Check Permission Method
    
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
    
    
    // MARK: - Helper Method to Find Document Directory
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    
    // MARK: - Load Memories Function
    
    func loadMemories() {
        memories.removeAll()
        
        // attempt to load all memories in our document directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        // loop over every file 
        for file in files {
            let filename = file.lastPathComponent
            
            // check that it ends with ".thumb" so we don't count each memory more than once
            if filename.hasSuffix(".thumb") {
                // get the root name of the memory (ie, without its path extension)
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                
                // create a full path from the memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                
                // add it to the memories array
                memories.append(memoryPath)
            }
        }
        
        // reload the list of memories
        collectionView?.reloadSections(IndexSet(integer: 1))
    }

}
