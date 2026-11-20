//
//  LoginViewModel.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI
import AuthenticationServices

class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var loginError: String?

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    #if DEBUG
    func signInLocally() {
        UserDefaults.standard.userId = "local-debug-user"
        UserDefaults.standard.userName = "Local"
        UserDefaults.standard.userEmail = "local@snoredetection.dev"
        UserDefaults.standard.isLoggedIn = true

        NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
    }
    #endif

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            loginError = "No s'ha pogut obtenir la credencial."
            return
        }

        let userId = credential.user
        UserDefaults.standard.userId = userId
        UserDefaults.standard.isLoggedIn = true

        if let fullName = credential.fullName?.givenName {
            UserDefaults.standard.userName = fullName
        }

        if let email = credential.email {
            UserDefaults.standard.userEmail = email
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        loginError = "Error en iniciar sessio: \(error.localizedDescription)"
    }
}
