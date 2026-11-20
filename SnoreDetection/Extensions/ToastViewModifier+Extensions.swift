//
//  ToastViewModifier+Extensions.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 23/3/25.
//

import SwiftUI

extension View {
  func toastView(toastManager: ToastManager) -> some View {
    self.modifier(ToastViewModifier(toastManager: toastManager))
  }
}

