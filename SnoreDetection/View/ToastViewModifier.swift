//
//  ToastViewModifier.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 23/3/25.
//

import SwiftUI

struct ToastViewModifier: ViewModifier {
  @ObservedObject var toastManager: ToastManager
  
  @State private var offsetY: CGFloat = -200
  @State private var opacity: Double = 0
  
  func body(content: Content) -> some View {
    ZStack(alignment: .top) {
      content
      
      if let toast = toastManager.currentToast {
        Text(toast.message)
          .font(.headline)
          .padding()
          .background(backgroundColor(for: toast.type))
          .foregroundColor(.white)
          .cornerRadius(12)
          .padding(.top, 40)
          .offset(y: offsetY)
          .opacity(opacity)
          .onAppear {
            withAnimation(.spring()) {
              offsetY = 0
              opacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
              withAnimation(.easeInOut) {
                offsetY = -200
                opacity = 0
              }
              
              // Amaguem el toast després de la sortida
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                toastManager.hide()
              }
            }
          }
      }
    }
  }
  
  func backgroundColor(for type: ToastType) -> Color {
    switch type {
    case .info: return Color.blue
    case .success: return Color.green
    case .error: return Color.red
    }
  }
}
