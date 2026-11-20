//
//  SleepTrackingView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

/*
import SwiftUI

struct SleepTrackingView: View {
  @EnvironmentObject var sleepDataManager: SleepDataManager
  @State private var isTracking = false
  @State private var timer: Timer?
  
  var body: some View {
    VStack {
      Text("Seguiment del Son")
        .font(.largeTitle)
        .padding()
      
      if isTracking {
        Text("Mitjana Soroll de Fons: \(sleepDataManager.currentPhase?.averageBackgroundNoise ?? 0.0, specifier: "%.2f") dB")
          .font(.headline)
          .padding()
        
        Button(action: stopTracking) {
          Text("Aturar Seguiment")
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
      } else {
        Button(action: startTracking) {
          Text("Iniciar Seguiment")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
      }
    }
    .onDisappear { stopTracking() } // Aturem el seguiment si l'usuari surt de la pantalla
  }
  
  // 🔹 Inicia el seguiment de la sessió de son
  func startTracking() {
    isTracking = true
    sleepDataManager.startNewSession()
    
    timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
      let simulatedNoise = Double.random(in: 40...60) // 🔹 Simulem valors entre 40-60 dB
      sleepDataManager.currentPhase?.addBackgroundNoiseLevel(simulatedNoise)
    }
  }
  
  // 🔹 Atura el seguiment de la sessió de son
  func stopTracking() {
    isTracking = false
    timer?.invalidate()
    timer = nil
    sleepDataManager.endCurrentSession()
  }
}
*/

/*
 import SwiftUI
 
 struct SleepTrackingView: View {
 @EnvironmentObject var sleepDataManager: SleepDataManager
 @StateObject private var viewModel: SleepTrackingViewModel
 
 init(sleepDataManager: SleepDataManager) {
 _viewModel = StateObject(wrappedValue: SleepTrackingViewModel(sleepDataManager: sleepDataManager))
 }
 
 var body: some View {
 VStack(spacing: 24) {
 Text(viewModel.isTracking ? "🔴 Gravació en curs..." : "🟢 Preparat per iniciar")
 .font(.title)
 
 Button(action: {
 viewModel.isTracking ? viewModel.stopTracking() : viewModel.startTracking()
 }) {
 Text(viewModel.isTracking ? "Atura Seguiment" : "Inicia Seguiment")
 .font(.headline)
 .padding()
 .background(viewModel.isTracking ? Color.red : Color.green)
 .foregroundColor(.white)
 .clipShape(Capsule())
 }
 }
 .padding()
 //.environmentObject(sleepDataManager) // 🔁 Passa l'entorn a la VM si cal
 }
 }
*/

/*
 import SwiftUI
 
 struct SleepTrackingView: View {
 @EnvironmentObject var sleepDataManager: SleepDataManager
 @EnvironmentObject var trackingViewModel: TrackingViewModel
 @EnvironmentObject var toastManager: ToastManager
 @StateObject private var viewModel: SleepTrackingViewModel
 
 init(sleepDataManager: SleepDataManager, toastManager: ToastManager) {
 _viewModel = StateObject(wrappedValue: SleepTrackingViewModel(sleepDataManager: sleepDataManager,
 toastManager: toastManager
 ))
 }
 
 var body: some View {
 VStack(spacing: 24) {
 Text(viewModel.isTracking ? "🔴 Gravació en curs..." : "🟢 Preparat per iniciar")
 .font(.title)
 
 // 🔊 Info RMS
 VStack(spacing: 12) {
 Text("🔊 Soroll actual (RMS):")
 Text(String(format: "%.5f", viewModel.currentRMS))
 .font(.headline)
 .foregroundColor(.blue)
 
 Text("📈 Mitjana sessió (RMS):")
 Text(String(format: "%.5f", viewModel.averageRMS))
 .font(.headline)
 .foregroundColor(.green)
 }
 
 // 🔘 Botó d'inici/aturada
 Button(action: {
 viewModel.isTracking ? viewModel.stopTracking() : viewModel.startTracking()
 }) {
 Text(viewModel.isTracking ? "Atura Seguiment" : "Inicia Seguiment")
 .font(.headline)
 .padding()
 .background(viewModel.isTracking ? Color.red : Color.green)
 .foregroundColor(.white)
 .clipShape(Capsule())
 }
 }
 .padding()
 .onReceive(trackingViewModel.$shouldStopTracking) { shouldStop in
 if shouldStop {
 print("🛑 SleepTrackingView rep l'ordre d'aturar el tracking")
 viewModel.stopTracking()
 }
 }
 .toastView(toastManager: toastManager)
 }
 }
*/

import SwiftUI

struct SleepTrackingView: View {
  //@EnvironmentObject var sleepDataManager: SleepDataManager
  @EnvironmentObject var trackingViewModel: TrackingViewModel
  @EnvironmentObject var toastManager: ToastManager
  @StateObject private var viewModel: SleepTrackingViewModel
  
  @State private var bedtime = Date()
  @State private var wakeTime = Calendar.current.date(byAdding: .hour, value: 8, to: Date())!
  /*
  init(sleepDataManager: SleepDataManager, toastManager: ToastManager) {
    _viewModel = StateObject(wrappedValue: SleepTrackingViewModel(sleepDataManager: sleepDataManager,
                                                                  toastManager: toastManager
                                                                 ))
  }
  */
  init(toastManager: ToastManager) {
    _viewModel = StateObject(wrappedValue: SleepTrackingViewModel())
  }

  var body: some View {
    VStack(spacing: 24) {
      SleepClockSelector(bedtime: $bedtime, wakeTime: $wakeTime)
      Text(viewModel.isTracking ? "🔴 Gravació en curs..." : "🟢 Preparat per iniciar")
        .font(.title)
      
      // 🔊 Info RMS
      VStack(spacing: 12) {
        Text("🔊 Soroll actual (RMS):")
        Text(String(format: "%.5f", viewModel.currentRMS))
          .font(.headline)
          .foregroundColor(.blue)
        
        Text("📈 Mitjana sessió (RMS):")
        Text(String(format: "%.5f", viewModel.averageRMS))
          .font(.headline)
          .foregroundColor(.green)
      }
      
      // 🔘 Botó d'inici/aturada
      Button(action: {
        viewModel.isTracking ? viewModel.stopTracking() : viewModel.startTracking()
      }) {
        Text(viewModel.isTracking ? "Atura Seguiment" : "Inicia Seguiment")
          .font(.headline)
          .padding()
          .background(viewModel.isTracking ? Color.red : Color.green)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
    }
    .padding()
    .onReceive(trackingViewModel.$shouldStopTracking) { shouldStop in
      if shouldStop {
        print("🛑 SleepTrackingView rep l'ordre d'aturar el tracking")
        viewModel.stopTracking()
      }
    }
    .toastView(toastManager: toastManager)
  }
}
