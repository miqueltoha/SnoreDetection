//
//  SnoringAvatarView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 19/3/25.
//

import SwiftUI

struct SnoringAvatarView: View {
  @State private var breathing = false
  @State private var snoreOpacity = 0.0
  @State private var snoreOffset: CGFloat = 0.0
  
  var body: some View {
    ZStack {
      // 💤 Avatar dormint
      Image(systemName: "person.crop.circle.fill") // Pots substituir per una imatge personalitzada
        .resizable()
        .frame(width: 100, height: 100)
        .foregroundColor(.blue)
        .offset(y: breathing ? -5 : 5) // 🔄 Moviment suau de respiració
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: breathing)
      
      // 😴 "Zzz" flotant
      Text("💤")
        .font(.largeTitle)
        .offset(y: snoreOffset)
        .opacity(snoreOpacity)
        .onAppear {
          startSnoringAnimation()
        }
    }
    .onAppear {
      breathing.toggle()
    }
  }
  
  // 🔄 Animació del ronc
  func startSnoringAnimation() {
    withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
      snoreOpacity = 1
      snoreOffset = -30
    }
  }
}

