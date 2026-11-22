//
//  SleepTrackingView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI

struct SleepTrackingView: View {
  @EnvironmentObject var trackingViewModel: TrackingViewModel
  @EnvironmentObject var toastManager: ToastManager
  @StateObject private var viewModel: SleepTrackingViewModel

  @State private var bedtime = Date()
  @State private var wakeTime = Calendar.current.date(byAdding: .hour, value: 8, to: Date())!
  @State private var isShowingPreparation = false
  @State private var selectedTags: Set<SleepContextTag> = []

  init(sleepDataManager: SleepDataManager, toastManager: ToastManager) {
    _viewModel = StateObject(
      wrappedValue: SleepTrackingViewModel(
        sleepDataManager: sleepDataManager,
        toastManager: toastManager
      )
    )
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
      Button(action: toggleTracking) {
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
    .sheet(isPresented: $isShowingPreparation) {
      SessionPreparationView(selectedTags: $selectedTags) {
        viewModel.startTracking(tags: selectedTags)
      }
    }
    .toastView(toastManager: toastManager)
  }

  private func toggleTracking() {
    if viewModel.isTracking {
      viewModel.stopTracking()
    } else {
      selectedTags.removeAll()
      isShowingPreparation = true
    }
  }
}
