//
//  LoginView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var loginVM = LoginViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Inicia sessio per continuar")
                .font(.headline)
                .padding(.bottom, 8)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    loginVM.authorizationController(
                        controller: ASAuthorizationController(authorizationRequests: [ASAuthorizationAppleIDProvider().createRequest()]),
                        didCompleteWithAuthorization: authResults
                    )
                case .failure(let error):
                    loginVM.loginError = error.localizedDescription
                }
            }
            .frame(width: 280, height: 45)
            .signInWithAppleButtonStyle(.black)

            #if DEBUG
            Button("Entrar en mode local") {
                loginVM.signInLocally()
            }
            .buttonStyle(.bordered)
            #endif

            if let error = loginVM.loginError {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
}
