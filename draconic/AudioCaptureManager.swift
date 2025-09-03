//
//  AudioCaptureManager.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import Foundation
import AVFoundation
import SwiftUI

@Observable
class AudioCaptureManager: NSObject {
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var audioBuffer = Data()
    
    var isRecording = false
    var onAudioCaptured: ((Data) -> Void)?
    
    override init() {
        super.init()
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                continuation.resume(returning: true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            case .denied, .restricted:
                continuation.resume(returning: false)
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        audioBuffer = Data()
        inputNode = audioEngine.inputNode
        
        let inputFormat = inputNode!.inputFormat(forBus: 0)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                          sampleRate: 16000, 
                                          channels: 1, 
                                          interleaved: false)!
        
        let converter = AVAudioConverter(from: inputFormat, to: recordingFormat)
        
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: AVAudioFrameCount(recordingFormat.sampleRate * Double(buffer.frameLength) / inputFormat.sampleRate))!
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }
            
            converter?.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if let channelData = convertedBuffer.int16ChannelData?[0] {
                let data = Data(bytes: channelData, count: Int(convertedBuffer.frameLength * 2))
                
                DispatchQueue.main.async {
                    self.audioBuffer.append(data)
                }
            }
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            print("Started recording")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        isRecording = false
        
        print("Stopped recording, captured \(audioBuffer.count) bytes")
        
        if !audioBuffer.isEmpty {
            onAudioCaptured?(createWAVData(from: audioBuffer))
        }
        
        audioBuffer = Data()
    }
    
    private func createWAVData(from pcmData: Data) -> Data {
        var wavData = Data()
        
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = UInt32(pcmData.count)
        var fileSize = (36 + dataSize).littleEndian
        
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(Data(bytes: &fileSize, count: 4))
        wavData.append("WAVE".data(using: .ascii)!)
        wavData.append("fmt ".data(using: .ascii)!)
        
        var fmtChunkSize = UInt32(16).littleEndian
        wavData.append(Data(bytes: &fmtChunkSize, count: 4))
        
        var audioFormat = UInt16(1).littleEndian
        wavData.append(Data(bytes: &audioFormat, count: 2))
        var channelsLE = channels.littleEndian
        wavData.append(Data(bytes: &channelsLE, count: 2))
        var sampleRateLE = sampleRate.littleEndian
        wavData.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        wavData.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        wavData.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsPerSampleLE = bitsPerSample.littleEndian
        wavData.append(Data(bytes: &bitsPerSampleLE, count: 2))
        
        wavData.append("data".data(using: .ascii)!)
        var dataSizeLE = dataSize.littleEndian
        wavData.append(Data(bytes: &dataSizeLE, count: 4))
        wavData.append(pcmData)
        
        return wavData
    }
}
