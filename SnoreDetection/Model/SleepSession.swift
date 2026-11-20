//
//  SleepSession.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import CloudKit
import CoreData

struct SleepSession: Identifiable {
  let id: UUID
  let startTime: Date
  let endTime: Date
  let totalDuration: TimeInterval
  let remDuration: TimeInterval
  let deepDuration: TimeInterval
  let lightDuration: TimeInterval
  let awakeDuration: TimeInterval
  let snoringDetected: Bool
  let snoreIntensity: Double
  let sleepQuality: Double
  let userNotes: String?
  
  // 🔹 Conversió a `CKRecord` per CloudKit
  func toCKRecord() -> CKRecord {
    let record = CKRecord(recordType: "SleepSession")
    record["id"] = id.uuidString
    record["startTime"] = startTime
    record["endTime"] = endTime
    record["totalDuration"] = totalDuration
    record["remDuration"] = remDuration
    record["deepDuration"] = deepDuration
    record["lightDuration"] = lightDuration
    record["awakeDuration"] = awakeDuration
    record["snoringDetected"] = snoringDetected
    record["snoreIntensity"] = snoreIntensity
    record["sleepQuality"] = sleepQuality
    record["userNotes"] = userNotes
    return record
  }
}
