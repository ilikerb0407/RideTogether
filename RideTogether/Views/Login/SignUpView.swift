//
//  SignUpView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import FirebaseAuth

// Temporary color extension until Color+Extension.swift is added to build target
extension Color {
    static let B2 = Color("B2")
    static let B5 = Color("B5")
}

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authState: AuthStateManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.B2
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Title
                    Text("RideTogether")
                        .font(.system(size: 30))
                        .foregroundColor(Color.B5)
                        .padding(.top, 100)
                    
                    // Lottie Animation
                    LottieView(animation: .named("bike-ride"))
                        .playing(loopMode: .loop)
                        .frame(width: 250, height: 250)
                        .padding(.bottom, 50)
                    
                    // Email TextField
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal, 40)
                    
                    // Password TextField
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.horizontal, 40)
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 40)
                    }
                    
                    // Buttons
                    HStack(spacing: 20) {
                        Button("Sign Up") {
                            signUp()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width: 100)
                        .disabled(isLoading)
                        
                        Button("Login") {
                            login()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width: 100)
                        .disabled(isLoading)
                    }
                    .padding(.top, 30)
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter an email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let authResult = authResult else { return }
            let uid = authResult.user.uid
            
            var userInfo = UserInfo()
            userInfo.uid = uid
            userInfo.email = email
            userInfo.userName = email.components(separatedBy: "@").first ?? "User"
            
            UserManager.shared.signUpUserInfo(userInfo: userInfo) { result in
                switch result {
                case .success:
                    fetchUserInfo(uid: uid)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter an email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let authResult = authResult else { return }
            let uid = authResult.user.uid
            
            if authResult.additionalUserInfo?.isNewUser == true {
                var userInfo = UserInfo()
                userInfo.uid = uid
                userInfo.email = email
                userInfo.userName = email.components(separatedBy: "@").first ?? "User"
                
                UserManager.shared.signUpUserInfo(userInfo: userInfo) { result in
                    switch result {
                    case .success:
                        fetchUserInfo(uid: uid)
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            } else {
                fetchUserInfo(uid: uid)
            }
        }
    }
    
    private func fetchUserInfo(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid) { result in
            switch result {
            case .success(let userInfo):
                UserManager.shared.userInfo = userInfo
                authState.userInfo = userInfo
                authState.isAuthenticated = true
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

