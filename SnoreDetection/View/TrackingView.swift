//
//  TrackingView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

/*
 import SwiftUI
 
 struct TrackingView: View {
 @EnvironmentObject var sleepDataManager: SleepDataManager // 🔹 L'hem de rebre com un `@EnvironmentObject`
 @State private var selectedTab = 0 // 🔹 Controlar l'animació de la pestanya seleccionada
 
 var body: some View {
 TabView(selection: $selectedTab) {
 SleepTrackingView(sleepDataManager: sleepDataManager)
 .tabItem {
 Label("Seguiment", systemImage: "waveform.path.ecg")
 }
 .tag(0)
 SleepHistoryView()
 .tabItem {
 Label("Històric", systemImage: "clock.arrow.circlepath")
 }
 .tag(1)
 .environmentObject(sleepDataManager)
 InsightsView()
 .tabItem {
 Label("Anàlisi", systemImage: "chart.bar.fill")
 }
 .tag(2)
 .environmentObject(sleepDataManager)
 SettingsView()
 .tabItem {
 Label("Configuració", systemImage: "gear")
 }
 .tag(3)
 .environmentObject(sleepDataManager)
 ProfileView()
 .tabItem {
 Label("Perfil", systemImage: "person.fill")
 }
 .tag(4)
 .environmentObject(sleepDataManager)
 }
 .animation(.easeInOut(duration: 0.3), value: selectedTab) // 🔥 Suavitza el canvi de pestanya
 }
 }
*/

import SwiftUI

struct TrackingView: View {
  //@EnvironmentObject var sleepDataManager: SleepDataManager
  @EnvironmentObject var toastManager: ToastManager
  @StateObject private var trackingViewModel = TrackingViewModel() // 🔹 Nova instància
  
  @State private var selectedTab = 0
  
  var body: some View {
    TabView(selection: $selectedTab) {
      SleepTrackingView(toastManager: toastManager)
        .tabItem {
          Label("Seguiment", systemImage: "waveform.path.ecg")
        }
        .tag(0)
      
      SleepHistoryView()
        .tabItem {
          Label("Històric", systemImage: "clock.arrow.circlepath")
        }
        .tag(1)
        //.environmentObject(sleepDataManager)
      
      InsightsView()
        .tabItem {
          Label("Anàlisi", systemImage: "chart.bar.fill")
        }
        .tag(2)
        //.environmentObject(sleepDataManager)
      
      SettingsView()
        .tabItem {
          Label("Configuració", systemImage: "gear")
        }
        .tag(3)
        //.environmentObject(sleepDataManager)
      
      ProfileView()
        .tabItem {
          Label("Perfil", systemImage: "person.fill")
        }
        .tag(4)
        //.environmentObject(sleepDataManager)
        .environmentObject(trackingViewModel)
    }
    .animation(.easeInOut(duration: 0.3), value: selectedTab)
    .onReceive(trackingViewModel.$shouldStopTracking) { shouldStop in
      if shouldStop {
        // 🔥 Aquí podries parar la sessió si cal
        print("⚠️ El tracking hauria de parar!")
        // Potser pots notificar al SleepTrackingViewModel d'alguna manera
      }
    }
    .environmentObject(trackingViewModel) // 🔁 En cas que altres vistes també el necessitin
    .environmentObject(toastManager)
  }
}
