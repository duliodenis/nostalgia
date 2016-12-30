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
    // the active memory
    var activeMemory: URL!
    // the AV Audio Recorder
    var audioRecorder: AVAudioRecorder?
    // the URL of the file used to record to
    var recordingURL: URL!
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add a nav bar button to add a photo
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPhoto))
        
        // set-up the recording file URL
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
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
    
    
    // MARK: - Load and Save Memories Functions
    
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
    
    
    func saveNewMemory(image: UIImage) {
        // create a unique name for the memory using seconds
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        // use the unique name to create filenames for the full size image and thumbnail
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        
        do {
            // create a URL where we can write a jpg to
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            // convert the UIImage to a JPEG data object
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                // write data to URL we created
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            // create thumbnail
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
            
        } catch {
            print("saveMemory: Failed to write to disk.")
        }
    }
    
    
    // MARK: - Add Photo Function
    
    func addPhoto() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    
    // MARK: - UICollectionView Delegate Methods
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // one for the search and one for the memories
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        
        let memory = memories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage.init(contentsOfFile: imageName)
        
        cell.imageView.image = image
        
        // check to see if the cell's gesture recognizer is nil
        if cell.gestureRecognizers == nil {
            // if it is add a long press recognizer to record narration
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
            
            // set the cell's border properties
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 3
            cell.layer.cornerRadius = 10
        }
        
        return cell
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    
    // MARK: - Memory URL Helper Methods
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    
    // MARK: - Resize Photo Helper Method
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        // calculate how much we need to bring our width size to match our target size
        let scale = width / image.size.width
        
        // bring the height down by the same amount to preserve the aspect ratio
        let height = image.size.height * scale
        
        // create a new image context we can draw into
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        // draw the original image into the context
        image.draw(in: CGRect(x: 0, y:0, width: width, height: height))
        
        // pull out the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end the context so UIKit can clean up
        UIGraphicsEndImageContext()
        
        // return resized image
        return newImage
    }
    
    
    // MARK: - Voice Recording Methods
    
    // Called from the long press gesture from a Collection View Cell
    
    func memoryLongPress(sender: UILongPressGestureRecognizer) {
        // if we have just started long pressing
        if sender.state == .began {
            // get the collection view cell
            let cell = sender.view as! MemoryCell
            
            // and derive the index
            if let index = collectionView?.indexPath(for: cell) {
                // to set the active memory variable
                activeMemory = memories[index.row]
                // and start recording
                recordNarration()
            }
        } else if sender.state == .ended {
            // if on the other hand we ended recording - call the finish recording method
            finishRecording(success: true)
        }
    }
    
    
    // Called to record the audio narration through the microphone
    
    func recordNarration() {
        // set the background color to RED to indicate recording is ON
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // configure the session for recording and playback through the speaker
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            
            // set-up a high quality recording session settings
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),                   // MP4 AAC
                            AVSampleRateKey: 44100,                                     // 44.1KHz
                            AVNumberOfChannelsKey: 2,                                   // Stereo
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]     // HQ Encoding
            
            // create the audio recording and assign ourself as the delegate
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            print("record narration: Error. Failed to record: \(error)")
            finishRecording(success: false)
        }
    }
    
    
    // Called when recording is finished and responsible for linking the recording to the memory
    
    func finishRecording(success: Bool) {
        // set the background color back to indicate recording is OFF
        collectionView?.backgroundColor = UIColor.darkGray
        
        // stop the recording
        audioRecorder?.stop()
        
        if success {
            do {
                // create a URL out of the active memory URL + m4a extension
                let audioMemoryURL = activeMemory.appendingPathComponent("m4a")
                let fm = FileManager.default
                
                // delete existing recordings
                if fm.fileExists(atPath: audioMemoryURL.path) {
                    try fm.removeItem(at: audioMemoryURL)
                }
                
                // move recorded file into the audio memory URL
                try fm.moveItem(at: recordingURL, to: audioMemoryURL)
                
                // kick-off the transcription
                transcriptionURL(for: audioMemoryURL)
            } catch let error {
                print("Failure Finishing Recording: \(error)")
            }
        }
    }
    
    
    // Responsible for transcribing narration into text and linking to the memory
    
    func transcribeAudio(memory: URL) {
        print("transcribing audio.")
    }

}


// MARK: - Image Picker Controller Delegate / Navigation Controller Delegate Methods

extension MemoriesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
}


// MARK: - Collection View Flow Layout Delegate Methods

extension MemoriesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
    
}


// MARK: - AV Audio Recording Delegate Methods

extension MemoriesViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finishRecording(success: false)
    }
    
}
