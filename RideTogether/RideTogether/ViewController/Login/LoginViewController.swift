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
import Lottie

class LoginViewController: BaseViewController, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        return self.view.window!
        
    }
    
    // MARK: - Class Properties -
    
    fileprivate var currentNonce: String?
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private var userInfo = UserManager.shared.userInfo
    
    private lazy var loginButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    
    var currentUser = Auth.auth().currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSignInButton()
        
        loginButtonFadeIn()
        
        if let user = Auth.auth().currentUser {
            print("\(user.uid) login")
            LKProgressHUD.showSuccess(text: "已經登入")
        } else {
            print("not login")
            LKProgressHUD.showFailure(text: "未登入")
        }
        
        Auth.auth().addStateDidChangeListener { _, user in
            
            if let user = user {
                print("\(user.uid) login")
            } else {
                print("not login")
            }
            
            self.currentUser = Auth.auth().currentUser
        }
        
        showAnimation()
    }
    
    func showAnimation() {

      var waveLottieView: LottieAnimationView = {
        
            let view = LottieAnimationView(name: "49908-bike-ride")
            
            view.loopMode = .loop
            view.frame = CGRect(x: UIScreen.width / 2 - 200, y: UIScreen.height / 2 - 200, width: 400, height: 350)
            view.contentMode = .scaleAspectFit
            view.play()
            self.view.addSubview(view)
            return view
        }()
    }
    
    @IBAction func goToPrivacyPage(_ sender: UIButton) {
        
        guard let policyVC = UIStoryboard.policy.instantiateViewController(
            identifier: PolicyViewController.identifier) as? PolicyViewController else { return }
        
        policyVC.policy = .privacy
        
        present(policyVC, animated: true, completion: nil)
    }
    
    @IBAction func goToEulaPage(_ sender: Any) {
        
        guard let policyVC = UIStoryboard.policy.instantiateViewController(
            identifier: PolicyViewController.identifier) as? PolicyViewController else { return }
        
        policyVC.policy = .eula
        
        present(policyVC, animated: true, completion: nil)
    }
    
//      https://www.privacypolicies.com/live/38b065d0-5b0e-4b1d-a8e0-f51274f8d269

    func setUpSignInButton() {
        
        view.addSubview(loginButton)
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        loginButton.addTarget(self, action: #selector(self.handleSignInWithAppleTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            
            loginButton.heightAnchor.constraint(equalToConstant: 45),
            
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 200)
        ])
        
        loginButton.alpha = 0.0
    }
    
    // MARK: - Methods -
    
    @objc func handleSignInWithAppleTapped() {
        
        let provider = ASAuthorizationAppleIDProvider()
        
        let request = provider.createRequest()
        
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        authorizationController.delegate = self
        
        authorizationController.presentationContextProvider = self
        
        authorizationController.performRequests()
        
        let nonce = randomNonceString()

        request.nonce = sha256(nonce)

        currentNonce = nonce
//
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
    
    @IBOutlet private(set) var emailbtn: UIButton!
    
    @objc func popUpEmailSignIn() {

        print(">>>> Button tapped ")
        
        if let nextVC = storyboard?.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
            
            self.modalPresentationStyle = .fullScreen
            
            self.present(nextVC, animated: true, completion: .none)
        }
        
    }
    func loginButtonFadeIn () {
        
        self.loginButton.alpha = 0.0
        self.emailbtn.alpha = 0.0
        self.emailbtn.titleLabel?.font = .boldSystemFont(ofSize: 17.5)
        self.emailbtn.addTarget(self, action: #selector(popUpEmailSignIn), for: .touchUpInside)
        
        emailbtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emailbtn.heightAnchor.constraint(equalToConstant: 45),
            
            emailbtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            
            emailbtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emailbtn.centerYAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 30)
            
        ])
        
        //        self.agreementStackView.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, delay: 2) {
            self.emailbtn.alpha = 1.0
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
        
//        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
//            let userId = credential.user
//            let fullname = credential.fullName
//            let email = credential.email
//            let idToken = credential.identityToken
//
//        } else { }
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            userInfo.userName = appleIDCredential.fullName?.givenName
            
            guard let nonce = currentNonce else {
                
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                LKProgressHUD.showFailure(text: "登入請求未送出")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                
                print("Unable to fetch identity token")
                LKProgressHUD.showFailure(text: "登入失敗")
                return
                
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                LKProgressHUD.showFailure(text: "登入失敗")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                
                if let isNewUser = authResult?.additionalUserInfo?.isNewUser,
                   
                    let uid = authResult?.user.uid {
                    
                    LKProgressHUD.show()
                    
                    if isNewUser {
                        
                        self.userInfo.uid = uid
                        
                        UserManager.shared.signUpUserInfo(userInfo: self.userInfo) { result in
                            
                            switch result {
                                
                            case .success:
                                
                                self.fetchUserInfo(uid: uid)
                            
                                LKProgressHUD.showSuccess(text: "註冊成功")
                                
                            case .failure(let error):
                                
                                LKProgressHUD.showFailure(text: "註冊失敗")
                                
                            }
                        }
                        
                    } else {
                        
                        self.fetchUserInfo(uid: uid)
                        LKProgressHUD.showSuccess(text: "登入成功")
                    }
                }
                
                if let error = error as? NSError {
                    
                    print(error)
                    guard let errorCode = AuthErrorCode(_bridgedNSError: error) else {
                        print("登入錯誤，請稍後再試")
                        return
                    }
                    LKProgressHUD.showFailure(text: "登入失敗，請確定網路品質")
                    
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        print("Sign in with Apple errored: \(error)")
        
        switch error {
            
        case ASAuthorizationError.canceled:
            LKProgressHUD.showFailure(text: "取消登入")
        case ASAuthorizationError.failed:
            LKProgressHUD.showFailure(text: "授權請求失敗")
        case ASAuthorizationError.invalidResponse:
            LKProgressHUD.showFailure(text: "授權請求無回應")
        case ASAuthorizationError.notHandled:
            LKProgressHUD.showFailure(text: "授權請求未處理")
        case ASAuthorizationError.unknown:
            LKProgressHUD.showFailure(text: "網路連線不佳")
        default:
            LKProgressHUD.showFailure(text: "登入失敗，原因不明")
        }
        
    }
    
    func fetchUserInfo (uid: String) {
        
        UserManager.shared.fetchUserInfo(uid: uid) { result in
            
            switch result {
                
            case .success(let userInfo):
                
                UserManager.shared.userInfo = userInfo
                
                guard let tabBarVC = UIStoryboard.main.instantiateViewController(
                    identifier: TabBarController.identifier) as? TabBarController else { return }
                
                tabBarVC.modalPresentationStyle = .fullScreen
                
                self.present(tabBarVC, animated: true, completion: nil)
                
            case .failure(let error):
                
                LKProgressHUD.showFailure(text: "讀取資料失敗")
            }
        }
    }
    
}
