//
//  SleepHistoryView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI
import CoreData

struct SleepHistoryView: View {
  @FetchRequest(
    entity: SleepSessionEntity.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \SleepSessionEntity.startTime, ascending: false)]
  ) var sleepSessions: FetchedResults<SleepSessionEntity>
  
  var body: some View {
    NavigationView {
      List(sleepSessions) { session in
        NavigationLink(destination: SleepSessionDetailView(session: session)) {
          VStack(alignment: .leading) {
            Text("Sessió: \(session.startTime ?? Date(), formatter: dateFormatter)")
              .font(.headline)
            Text("Qualitat del son: \(session.sleepQuality, specifier: "%.2f")")
              .font(.subheadline)
              .foregroundColor(.gray)
          }
        }
      }
      .navigationTitle("Històric de Sessions")
    }
  }
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()
