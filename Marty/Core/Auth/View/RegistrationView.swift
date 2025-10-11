//
//  RegistrationView.swift
//  Marty
//
//  Created by iVan on 10/10/25.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject var viewModel = RegistrationViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Spacer()
            Image("marta-logo")
                .resizable()
                .scaledToFit()
                .frame(width:130, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding()
            
            // Login information fields.
            VStack {
                
                TextField("Enter your email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .modifier(TextFieldModifier())
                
                SecureField("Enter your password", text: $viewModel.password)
                    .modifier(TextFieldModifier())
                
                TextField("Enter your username", text: $viewModel.username)
                    .modifier(TextFieldModifier())
                    .textInputAutocapitalization(.never)
                
                TextField("Enter your display name", text: $viewModel.displayName)
                    .modifier(TextFieldModifier())
                    .textInputAutocapitalization(.words)
                
                Button {
                    Task {
                        do {
                            try await viewModel.createUser()
                        } catch {
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                } label: {
                    Text("Sign up")
                        .modifier(ButtonModifier())
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            Divider()
            
            Button {
                dismiss()
            } label: {
                VStack (spacing: 3) {
                    Text("Already have an account?")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Text(" Sign in")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 10)
                .foregroundColor(.black)
            }

        }
        .alert("Registration Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    RegistrationView()
}
