//
//  SnoreDetectionApp.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI

@main
struct SnoreDetectionApp: App {
  @StateObject private var appState = AppState()
  //@StateObject var sleepDataManager = SleepDataManager()
  @StateObject var toastManager = ToastManager()
  let persistenceController = PersistenceController.shared
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appState)
        //.environmentObject(sleepDataManager)
        .environmentObject(toastManager)
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .onAppear {
          NotificationCenter.default.addObserver(forName: Notification.Name("DidRegisterForRemoteNotifications"), object: nil, queue: .main) { notification in
            if let token = notification.object as? Data {
              appState.pushNotificationManager.updateDeviceToken(token)
            }
          }
        }
    }
  }
}
