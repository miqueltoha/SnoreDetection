  //
  //  SleepDataManager.swift
  //  SnoreDetection
  //
  //  Created by Miquel Toha Perera on 17/3/25.
  //

  //NYAP
  /*
   import CoreData
   import CloudKit
   
   class SleepDataManager: ObservableObject {
   static let shared = SleepDataManager()
   private let container: NSPersistentContainer
   
   init() {
   container = NSPersistentContainer(name: "SleepModel")
   container.loadPersistentStores { _, error in
   if let error = error {
   print("❌ Error carregant CoreData: \(error.localizedDescription)")
   }
   }
   }
   
   func saveSleepSession(_ session: SleepSession) {
   let context = container.viewContext
   let newSession = SleepSessionEntity(context: context)
   newSession.id = session.id
   newSession.startTime = session.startTime
   newSession.endTime = session.endTime
   newSession.totalDuration = session.totalDuration
   newSession.remDuration = session.remDuration
   newSession.deepDuration = session.deepDuration
   newSession.lightDuration = session.lightDuration
   newSession.awakeDuration = session.awakeDuration
   newSession.snoringDetected = session.snoringDetected
   newSession.snoreIntensity = session.snoreIntensity
   newSession.sleepQuality = session.sleepQuality
   newSession.userNotes = session.userNotes
   
   do {
   try context.save()
   print("✅ Sessió de son guardada correctament!")
   } catch {
   print("❌ Error guardant la sessió: \(error.localizedDescription)")
   }
   }
   
   func fetchAllSessions() -> [SleepSessionEntity] {
   let context = container.viewContext
   let request: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
   do {
   return try context.fetch(request)
   } catch {
   print("❌ Error obtenint sessions: \(error.localizedDescription)")
   return []
   }
   }
   }
  */

import CoreData
import SwiftUI

class SleepDataManager: ObservableObject {
  /*
   static let shared = SleepDataManager()
   private let viewContext: NSManagedObjectContext
   
   
   private init() {
   viewContext = PersistenceController.shared.container.viewContext
   }
   */
  
  @Published var currentSession: SleepSessionEntity?
  @Published var currentPhase: SleepPhaseEntity?
  
  private let context = PersistenceController.shared.container.viewContext
  
  func createSleepSession() -> SleepSessionEntity {
    let newSession = SleepSessionEntity(context: context)
    newSession.id = UUID()
    newSession.startTime = Date()
    newSession.sleepQuality = 0.0
    try? context.save()
    return newSession
  }
  
  func endSleepSession(session: SleepSessionEntity) {
    session.endTime = Date()
    try? context.save()
  }
  
  // 🔹 Crea una nova sessió de son
  func startNewSession() {
    let session = SleepSessionEntity(context: context)
    session.id = UUID()
    session.startTime = Date()
    
    let phase = SleepPhaseEntity(context: context)
    phase.startTime = Date()
    phase.session = session // 🔹 Assigna la fase a la sessió
    
    currentSession = session
    currentPhase = phase
    saveContext()
  }
  
  // 🔹 Finalitza la sessió de son
  func endCurrentSession() {
    currentSession?.endTime = Date()
    saveContext()
    currentSession = nil
    currentPhase = nil
  }
  
  /// 📌 Afegir una nova sessió de son
  func addSleepSession(startTime: Date, endTime: Date, sleepQuality: Double) {
    let newSession = SleepSessionEntity(context: context)
    newSession.id = UUID()
    newSession.startTime = startTime
    newSession.endTime = endTime
    newSession.sleepQuality = sleepQuality
    
    saveContext()
  }
  
  func addSleepPhase(to session: SleepSessionEntity, phaseType: String, startTime: Date, endTime: Date, snoringIntensity: Double?, oxygenLevel: Double?, bodyMovement: Double?, heartRate: Double?) {
    let newPhase = SleepPhaseEntity(context: context)
    newPhase.id = UUID()
    newPhase.phaseType = phaseType
    newPhase.startTime = startTime
    newPhase.endTime = endTime
    newPhase.snoringIntensity = snoringIntensity ?? 0.0
    newPhase.oxygenLevel = oxygenLevel ?? 0.0
    newPhase.bodyMovement = bodyMovement ?? 0.0
    newPhase.heartRate = heartRate ?? 0.0
    newPhase.session = session // 🔹 Relacionem la fase amb la sessió
    
    saveContext()
  }
  
  func addSoundEvent(to phase: SleepPhaseEntity, eventType: String, startTime: Date, endTime: Date, intensity: Double, frequency: Double?, possibleApnea: Bool?) {
    let newSoundEvent = SoundEventEntity(context: context)
    newSoundEvent.id = UUID()
    newSoundEvent.eventType = eventType
    newSoundEvent.startTime = startTime
    newSoundEvent.endTime = endTime
    newSoundEvent.intensity = intensity
    newSoundEvent.duration = endTime.timeIntervalSince(startTime)
    newSoundEvent.frequency = frequency ?? 0.0
    newSoundEvent.possibleApnea = possibleApnea ?? false
    newSoundEvent.phase = phase // 🔹 Relacionem el so amb la fase del son
    
    phase.addToSoundEvents(newSoundEvent) // 🔹 Afegim el so a la fase
    
    saveContext()
  }
  
  /// 📌 Recuperar totes les sessions de son
  func fetchSleepSessions() -> [SleepSessionEntity] {
    let fetchRequest: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
    
    do {
      return try context.fetch(fetchRequest)
    } catch {
      print("❌ Error recuperant sessions de son: \(error.localizedDescription)")
      return []
    }
  }
  
  /// 📌 Esborrar una sessió de son
  func deleteSleepSession(_ session: SleepSessionEntity) {
    context.delete(session)
    saveContext()
  }
  
  /// 📌 Guardar canvis a `CoreData`
  private func saveContext() {
    do {
      try context.save()
    } catch {
      print("❌ Error guardant dades: \(error.localizedDescription)")
    }
  }
}
