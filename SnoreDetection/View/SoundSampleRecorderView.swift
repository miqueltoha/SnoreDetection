//
//  SoundSampleRecorderView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 15/4/25.
//

import SwiftUI

struct SoundSampleRecorderView: View {
  @StateObject private var viewModel = SoundSampleRecorderViewModel()
  @State private var showSaveButtons = false
  @State private var saveConfirmation: String?
  
  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Spacer()
        
        Text("🎙️ Gravació d'1 segon")
          .font(.title2)
          .bold()
        
        if viewModel.isRecording {
          ProgressView("Gravant...")
            .progressViewStyle(CircularProgressViewStyle())
        } else {
          Button(action: {
            viewModel.startRecording()
            showSaveButtons = true
            saveConfirmation = nil
          }) {
            Text("Iniciar gravació")
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.accentColor)
              .foregroundColor(.white)
              .cornerRadius(10)
          }
        }
        
        if showSaveButtons && !viewModel.isRecording {
          VStack(spacing: 12) {
            Button(action: {
              viewModel.saveRecording(label: "snore")
              showSaveButtons = false
              saveConfirmation = "✅ Ronc guardat!"
            }) {
              Text("Guardar com Ronc")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
              viewModel.saveRecording(label: "no_snore")
              showSaveButtons = false
              saveConfirmation = "✅ No ronc guardat!"
            }) {
              Text("Guardar com No Ronc")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
          }
        }
        
        if let message = saveConfirmation {
          Text(message)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.top, 8)
        }
        
        Spacer()
      }
      .padding()
      .navigationTitle("Afegir so etiquetat")
    }
  }
}

#Preview {
  SoundSampleRecorderView()
}
