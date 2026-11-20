//
//  ProfileView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI

struct ProfileView: View {
  @EnvironmentObject var appState: AppState // 🔹 Per controlar l'estat de la sessió
  @EnvironmentObject var trackingViewModel: TrackingViewModel
  @State private var showLogoutAlert = false // 🔥 Control de l'alerta
  @AppStorage("userName") private var userName: String = ""
  @AppStorage("userEmail") private var userEmail: String = ""
  
  var body: some View {
    VStack {
      Text("👤 Perfil d'usuari")
        .font(.largeTitle)
        .padding()
      
      TextField("Nom", text: $userName)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
      
      TextField("Email", text: $userEmail)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
      
      Button("Guardar") {
        UserDefaults.standard.userName = userName
        UserDefaults.standard.userEmail = userEmail
        //NYAP actualitzar cloudKit?
      }
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(10)
      
      Spacer().frame(height: 40)
      
      Button(action: {
        print("Sessió tancada!")
        showLogoutAlert = true // 🔥 Mostra l'alerta abans de fer logout
      }) {
        Text("Tancar sessió")
          .font(.headline)
          .padding()
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .alert(isPresented: $showLogoutAlert) {
        Alert(
          title: Text("Vols tancar la sessió?"),
          message: Text("Si tanques la sessió, hauràs d'iniciar sessió de nou."),
          primaryButton: .destructive(Text("Tancar Sessió")) {
            logout() // 🔥 Executa la funció de logout
          },
          secondaryButton: .cancel()
        )
      }
    }
  }
  
  func logout() {
    // 🔹 Eliminar dades de l'usuari
    UserDefaults.standard.clearUserData()
    UserDefaults.standard.synchronize()
    
    // 🔹 Canviar l'estat de `isLoggedIn` per tornar a `LoginView`
    DispatchQueue.main.async {
      trackingViewModel.logoutUser()
      appState.isLoggedIn = false
    }
  }
}
