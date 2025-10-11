//
//  RegistrationViewModel.swift
//  Marty
//
//  Created by iVan on 10/10/25.
//

import Foundation
import Combine

class RegistrationViewModel: ObservableObject {
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var email = ""
    @Published var username = ""
    @Published var displayName = ""
    
    var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !username.isEmpty && 
        !displayName.isEmpty && 
        passwordsMatch
    }
    
    @MainActor
    func createUser() async throws {
        guard passwordsMatch else {
            throw RegistrationError.passwordsMismatch
        }
        
//        try await AuthService.shared.createUser(
//            withEmail: email,
//            password: password,
//            displayName: displayName,
//            username: username
//        )
    }
}

enum RegistrationError: Error, LocalizedError {
    case passwordsMismatch
    
    var errorDescription: String? {
        switch self {
        case .passwordsMismatch:
            return "Passwords do not match"
        }
    }
}

