//
//  LoginView.swift
//  Marty
//
//  Created by iVan on 10/10/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var username: String = ""
    @State private var password: String = ""
//    @State private var isLoading: Bool = false
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image("marta-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width:130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                
                VStack {
                    TextField("Username", text: $username)
                        .modifier(TextFieldModifier())
                    
                    SecureField("Password", text: $password)
                        .modifier(TextFieldModifier())
                    
                    Button {
                        
                    } label: {
                        Text("Login")
                            .modifier(ButtonModifier())
                    }.padding(.top)

                    NavigationLink {
                        Text("Forgot Password?")
                    } label: {
                        Text("Forgot Password?")
                            .font(.footnote.bold())
                            .padding(.vertical)
                    }
                    
                    
                }
                
                Spacer()
                
                Divider()
                
                NavigationLink {
                                    RegistrationView()
                                        .navigationBarBackButtonHidden(true)
                                } label: {
                                    HStack (spacing: 3) {
                                        Text("Create a new account")
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .bold()
                                    } .padding(.vertical, 10)
                                }
            }
        }
        .navigationBarTitle("Login")
    }
}

#Preview {
    LoginView()
}
