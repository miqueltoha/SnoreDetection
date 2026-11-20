//
//  AudioRecorderManager.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 21/3/25.
//

import AVFoundation
import Combine

class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
  private var audioRecorder: AVAudioRecorder?
  private var audioSession: AVAudioSession = .sharedInstance()
  
  @Published var isRecording = false
  @Published var hasInterruption = false
  
  override init() {
    super.init()
    setupAudioSession()
  }
  
  private func setupAudioSession() {
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .allowBluetooth])
      try audioSession.setActive(true)
      print("✅ Sessió d'àudio configurada correctament.")
    } catch {
      print("❌ Error configurant la sessió d'àudio: \(error.localizedDescription)")
    }
  }
  
  func startRecording() {
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("sleep_audio.m4a")
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: 16000,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    do {
      audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
      audioRecorder?.delegate = self
      audioRecorder?.record()
      isRecording = true
      print("🎤 Gravació iniciada a \(fileURL.path)")
    } catch {
      print("❌ Error iniciant la gravació: \(error.localizedDescription)")
    }
  }
  
  func stopRecording() {
    audioRecorder?.stop()
    isRecording = false
    print("⏹ Gravació aturada")
  }
  
  func handleInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
    
    if type == .began {
      print("⏸ Interrupció detectada")
      hasInterruption = true
      audioRecorder?.pause()
    } else if type == .ended {
      print("▶️ Interrupció finalitzada")
      hasInterruption = false
      audioRecorder?.record()
    }
  }
  
  //NYAP delegats que probablement no faré servir
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      print("✅ Gravació finalitzada correctament")
    } else {
      print("❌ La gravació no s’ha finalitzat amb èxit")
    }
  }
  
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    print("❌ Error codificant l'àudio: \(error?.localizedDescription ?? "desconegut")")
  }
}

