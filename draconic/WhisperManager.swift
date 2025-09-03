//
//  WhisperManager.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import Foundation
import WhisperKit
import AVFoundation

@Observable
class WhisperManager {
    private var whisperKit: WhisperKit?
    private var isLoading = false
    
    var transcribedText: String = ""
    var isTranscribing: Bool = false
    
    init() {
        Task {
            await setupWhisperKit()
        }
    }
    
    private func setupWhisperKit() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            print("🚀 Initializing WhisperKit with auto-download...")
            let config = WhisperKitConfig(model: "large-v3")
            whisperKit = try await WhisperKit(config)
            print("✅ WhisperKit initialized successfully")
        } catch {
            print("❌ Failed to initialize WhisperKit: \(error)")
        }
        
        isLoading = false
    }
    
    func transcribe(audioData: Data) async {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not initialized")
            return
        }
        
        isTranscribing = true
        
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio.wav")
            try audioData.write(to: tempURL)
            
            let results = try await whisperKit.transcribe(audioPath: tempURL.path)
            
            await MainActor.run {
                if let firstResult = results.first, !firstResult.text.isEmpty {
                    self.transcribedText = firstResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            try FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Transcription failed: \(error)")
        }
        
        isTranscribing = false
    }
    
    func clearText() {
        transcribedText = ""
    }
}
