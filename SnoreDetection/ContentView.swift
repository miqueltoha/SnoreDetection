//
//  ContentView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var sleepDataManager: SleepDataManager
  @EnvironmentObject var toastManager: ToastManager
  @State private var showAvatar = true // 🔹 Estat per mostrar l'avatar inicialment
  
  var body: some View {
    VStack {
      if showAvatar {
        SnoringAvatarView()
          .transition(.opacity)
          .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // 🔹 Després de 2s, passem al login
              withAnimation {
                showAvatar = false
              }
            }
          }
      } else {
        if appState.isLoggedIn {
          TrackingView()
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .environmentObject(sleepDataManager)
            .environmentObject(toastManager)
        } else {
          LoginView()
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
      }
    }
    .animation(.easeInOut(duration: 0.5), value: showAvatar)
    .onAppear {
      //appState.checkLoginStatus()
      NotificationCenter.default.addObserver(forName: NSNotification.Name("UserLoggedIn"), object: nil, queue: .main) { _ in
        appState.isLoggedIn = true
      }
    }
  }
}

