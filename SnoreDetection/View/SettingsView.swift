//
//  SettingsView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI

struct SettingsView: View {
  @State private var showRecorder = false
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Desenvolupador")) {
          NavigationLink(
            destination: SoundSampleRecorderView(),
            isActive: $showRecorder
          ) {
            Text("🎙️ Afegir so etiquetat")
          }
        }
      }
      .navigationTitle("Configuració")
    }
  }
}
