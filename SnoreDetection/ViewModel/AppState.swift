//
//  AppState.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI
import CoreData

@MainActor
class AppState: ObservableObject {
  static let shared = AppState()
      
  private let persistenceController = PersistenceController.shared
  private var context: NSManagedObjectContext {
    persistenceController.container.viewContext
  } // ✅ Afegit context
  
  @Published var isLoggedIn = false
  @Published var pushNotificationManager: PushNotificationManager
  
  init() {
    self.pushNotificationManager = PushNotificationManager()
    checkLoginStatus()
  }
  
  func checkLoginStatus() {
    //NYAP
    if let userID = UserDefaults.standard.userId {
      print("✅ Usuari detectat: \(userID)")
      isLoggedIn = true
      //NYAP eliminar
      //createSleepSession()
    } else {
      print("🔴 No s'ha detectat usuari")
      isLoggedIn = false
    }
  }
  
  //NYAP creem sessio fake
  private func createSleepSession() {
    let newSession = SleepSessionEntity(context: context)
    newSession.id = UUID()
    newSession.startTime = Date()
    newSession.endTime = Date() + 100
    newSession.sleepQuality = 0.0
    
    do {
      try context.save()
      print("✅ Nova SleepSession guardada a CoreData: \(newSession.id!)")
    } catch {
      print("❌ Error guardant SleepSession: \(error.localizedDescription)")
    }
  }
}
