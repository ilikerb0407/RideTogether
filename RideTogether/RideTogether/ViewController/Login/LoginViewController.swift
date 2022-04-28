//
//  LoginViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth

class LoginViewController: BaseViewController, ASAuthorizationControllerPresentationContextProviding {
    
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        return self.view.window!
        
    }
    
    // MARK: - Class Properties -
    
    fileprivate var currentNonce: String?
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private var userInfo = UserManager.shared.userInfo
    
    private lazy var loginButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
    
    
    var curerentUser = Auth.auth().currentUser
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSignInButton()
        
        loginButtonFadeIn()
        
        if let user = Auth.auth().currentUser {
            print("\(user.uid) login")
        } else {
            print("not login")
        }
        
        Auth.auth().addStateDidChangeListener { auth, user in
            
            if let user = user {
                   print("\(user.uid) login")
               } else {
                   print("not login")
               }
            
            self.curerentUser = Auth.auth().currentUser
        }
    }
    
    func setUpSignInButton() {
        
        view.addSubview(loginButton)
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        loginButton.addTarget(self, action: #selector(handleSignInWithAppleTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            
            loginButton.heightAnchor.constraint(equalToConstant: 36),
            
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 200)
        ])
        
        loginButton.alpha = 0.0
    }
    
    
    
    
    // MARK: - Methods -
    
    @objc func handleSignInWithAppleTapped() {
        
        performSignIn()
    }
    
    func performSignIn() {
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
        
        let nonce = randomNonceString()
        
        request.nonce = sha256(nonce)
        
        currentNonce = nonce
        
    }
    
    //    func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
    //
    //        let appleIDProvider = ASAuthorizationAppleIDProvider()
    //
    //        let request = appleIDProvider.createRequest()
    //
    //        request.requestedScopes = [.fullName, .email]
    //
    //        return request
    //    }
    
    private func sha256(_ input: String) -> String {
        
        let inputData = Data(input.utf8)
        
        let hashedData = SHA256.hash(data: inputData)
        
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    
    
    func loginButtonFadeIn () {
        
        self.loginButton.alpha = 0.0
        
        //        self.agreementStackView.alpha = 0.0
        
        //        appLogo.translatesAutoresizingMaskIntoConstraints = false
        
        UIView.animate(withDuration: 0.5, delay: 1) {
            
            //            self.logoTopConstrain.constant = 150
        }
        
        UIView.animate(withDuration: 0.5, delay: 1.5) {
            
            self.loginButton.alpha = 1.0
            //            self.agreementStackView.alpha = 1.0
        }
    }
    
    
    
}

private func randomNonceString(length: Int = 32) -> String {
    
    precondition(length > 0)
    
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    
    var result = ""
    
    var remainingLength = length
    
    while remainingLength > 0 {
        
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
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

extension LoginViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = credential.user
            let fullname = credential.fullName
            let email = credential.email
            let idToken = credential.identityToken
            
            print("---------\(userId)")
            print("---------\(fullname)")
            print("---------\(email)")
            print("---------\(idToken)")
            //                   guard let vc = storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
            //                   vc.modalPresentationStyle = .fullScreen
            //                   self.present(vc, animated: true)
        }
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            userInfo.userName = appleIDCredential.fullName?.givenName
            
            guard let nonce = currentNonce else {
                
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                
                print("Unable to fetch identity token")
                
                return
                
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                
                if let isNewUser = authResult?.additionalUserInfo?.isNewUser,
                   
                    let uid = authResult?.user.uid {
                    
                    if isNewUser {
                        
                        self.userInfo.uid = uid
                        
                        UserManager.shared.signUpUserInfo(userInfo: self.userInfo) { result in
                            
                            switch result {
                                
                            case .success:
                                
                                print ("\(credential.idToken)")
                                
                                self.fetchUserInfo(uid: uid)
                                
                                print("User Sign up successfully")
                                
                            case .failure(let error):
                                
                                print("Sign up failure: \(error)")
                            }
                        }
                        
                    } else {
                        
                        self.fetchUserInfo(uid: uid)
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        print("Sign in with Apple errored: \(error)")
    }
    
    func fetchUserInfo (uid: String) {
        
        UserManager.shared.fetchUserInfo(uid: uid) { result in
            
            switch result {
                
            case .success(let userInfo):
                
                UserManager.shared.userInfo = userInfo
                
                print("Fetch user info successfully")
                
                guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                    identifier: TabBarController.identifier) as? TabBarController else { return }
                
                tabbarVC.modalPresentationStyle = .fullScreen
                
                self.present(tabbarVC, animated: true, completion: nil)
                
            case .failure(let error):
                
                print("Fetch user info failure: \(error)")
            }
        }
    }
    
}