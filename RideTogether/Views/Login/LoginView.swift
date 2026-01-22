//
//  LoginView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Lottie

struct LoginView: View {
    @EnvironmentObject var authState: AuthStateManager
    @State private var showSignUp = false
    @State private var showPrivacy = false
    @State private var showEULA = false
    @State private var currentNonce: String?
    @State private var loginButtonOpacity: Double = 0
    @State private var emailButtonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.B2
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title
                Text("RideTogether")
                    .font(.system(size: 30))
                    .foregroundColor(Color.B5)
                    .padding(.top, 100)

                // Lottie Animation
                LottieView(animation: .named("bike-ride"))
                    .playing(loopMode: .loop)
                    .frame(width: 400, height: 350)
                    .padding(.top, -50)

                Spacer()

                // Buttons
                VStack(spacing: 30) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                            let nonce = randomNonceString()
                            request.nonce = sha256(nonce)
                            currentNonce = nonce
                        },
                        onCompletion: { result in
                            handleSignInWithApple(result: result)
                        }
                    )
                    .frame(height: 45)
                    .cornerRadius(6)
                    .padding(.horizontal, 40)
                    .opacity(loginButtonOpacity)

                    // Email Sign In Button
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Sign in with Email")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color.black)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 40)
                    .opacity(emailButtonOpacity)
                }
                .padding(.bottom, 40)

                // Terms and Privacy
                VStack(spacing: 0) {
                    Text("點擊登入鍵，即代表您同意下列")
                        .font(.system(size: 11))
                        .foregroundColor(.black)

                    HStack(spacing: 5) {
                        Button(action: {
                            showPrivacy = true
                        }) {
                            UnderlinedText(text: "隱私權政策")
                                .font(.system(size: 11))
                        }

                        Text("&")
                            .font(.system(size: 13))

                        Button(action: {
                            showEULA = true
                        }) {
                            UnderlinedText(text: "應用程式終端使用者授權協議")
                                .font(.system(size: 11))
                        }
                    }
                }
                .padding(.bottom, 15)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showPrivacy) {
            PolicyView(policy: .privacy)
        }
        .sheet(isPresented: $showEULA) {
            PolicyView(policy: .eula)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
                loginButtonOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(2.0)) {
                emailButtonOpacity = 1.0
            }
        }
    }
    
    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Sign in error: \(error.localizedDescription)")
                    return
                }
                
                guard let authResult = authResult else { return }
                let uid = authResult.user.uid
                
                if authResult.additionalUserInfo?.isNewUser == true {
                    handleNewUser(uid: uid, appleIDCredential: appleIDCredential)
                } else {
                    handleExistingUser(uid: uid)
                }
            }
            
        case .failure(let error):
            print("Apple Sign In Error: \(error.localizedDescription)")
        }
    }
    
    private func handleNewUser(uid: String, appleIDCredential: ASAuthorizationAppleIDCredential) {
        var userInfo = UserInfo()
        userInfo.uid = uid
        userInfo.userName = appleIDCredential.fullName?.givenName ?? "User"
        userInfo.email = appleIDCredential.email
        
        UserManager.shared.signUpUserInfo(userInfo: userInfo) { result in
            switch result {
            case .success:
                fetchUserInfo(uid: uid)
            case .failure(let error):
                print("Sign up error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleExistingUser(uid: String) {
        fetchUserInfo(uid: uid)
    }
    
    private func fetchUserInfo(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid) { result in
            switch result {
            case .success(let userInfo):
                UserManager.shared.userInfo = userInfo
                authState.userInfo = userInfo
                authState.isAuthenticated = true
            case .failure(let error):
                print("Fetch user info error: \(error.localizedDescription)")
            }
        }
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

// MARK: - Lottie View Wrapper

struct LottieView: UIViewRepresentable {
    let animation: LottieAnimation?
    var loopMode: LottieLoopMode = .loop
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(animation: animation)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        uiView.loopMode = loopMode
    }
}

extension LottieView {
    func playing(loopMode: LottieLoopMode = .loop) -> LottieView {
        var view = self
        view.loopMode = loopMode
        return view
    }
}

// MARK: - Underlined Text View (iOS 13.0+ compatible)

struct UnderlinedText: View {
    let text: String
    
    var body: some View {
        if #available(iOS 15.0, *) {
            Text(text)
                .underline()
        } else {
            Text(text)
                .overlay(
                    GeometryReader { geometry in
                        Rectangle()
                            .frame(height: 1)
                            .offset(y: geometry.size.height - 2)
                    }
                )
        }
    }
}

