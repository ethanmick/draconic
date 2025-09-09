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
    var realtimeText: String = ""
    var finalText: String = ""
    var isTranscribing: Bool = false
    var isRealtimeTranscribing: Bool = false
    var isFinalTranscribing: Bool = false
    
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
    
    func transcribeRealtime(audioData: Data) async {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not initialized")
            return
        }
        
        isRealtimeTranscribing = true
        
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_realtime_audio.wav")
            try audioData.write(to: tempURL)
            
            let results = try await whisperKit.transcribe(audioPath: tempURL.path)
            
            await MainActor.run {
                if let firstResult = results.first, !firstResult.text.isEmpty {
                    let newText = firstResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !newText.isEmpty {
                        if self.realtimeText.isEmpty {
                            self.realtimeText = newText
                        } else {
                            // Append new text, avoiding duplication
                            let words = newText.components(separatedBy: .whitespaces)
                            let existingWords = self.realtimeText.components(separatedBy: .whitespaces)
                            let newWords = words.filter { !existingWords.contains($0) }
                            if !newWords.isEmpty {
                                self.realtimeText += " " + newWords.joined(separator: " ")
                            }
                        }
                    }
                }
            }
            
            try FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Realtime transcription failed: \(error)")
        }
        
        isRealtimeTranscribing = false
    }
    
    func transcribeFinal(audioData: Data) async {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not initialized")
            return
        }
        
        isFinalTranscribing = true
        
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_final_audio.wav")
            try audioData.write(to: tempURL)
            
            let results = try await whisperKit.transcribe(audioPath: tempURL.path)
            
            await MainActor.run {
                if let firstResult = results.first, !firstResult.text.isEmpty {
                    self.finalText = firstResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Final transcription completed: \(self.finalText)")
                }
            }
            
            try FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Final transcription failed: \(error)")
        }
        
        isFinalTranscribing = false
    }
    
    func clearText() {
        transcribedText = ""
        realtimeText = ""
        finalText = ""
    }
}
