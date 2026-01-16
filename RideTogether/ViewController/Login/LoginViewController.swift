//
//  LoginViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Lottie
import UIKit

internal class LoginViewController: BaseViewController, ASAuthorizationControllerPresentationContextProviding {

    // MARK: - UI Components
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "RideTogether"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30)
        label.textColor = UIColor.B5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var lottieAnimationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "bike-ride")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var loginButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleSignInWithAppleTapped), for: .touchUpInside)
        button.alpha = 0.0
        return button
    }()
    
    private lazy var emailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Email", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 19)
        button.backgroundColor = .black
        button.tintColor = .tertiarySystemGroupedBackground
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(popUpEmailSignIn), for: .touchUpInside)
        button.alpha = 0.0
        return button
    }()
    
    private lazy var termsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let termsLabel = UILabel()
        termsLabel.text = "點擊登入鍵，即代表您同意下列"
        termsLabel.font = UIFont(name: ".PingFangTC-Regular", size: 11) ?? .systemFont(ofSize: 11)
        termsLabel.textAlignment = .center
        termsLabel.numberOfLines = 0
        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let linksStackView = UIStackView()
        linksStackView.axis = .horizontal
        linksStackView.spacing = 5
        linksStackView.alignment = .center
        linksStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let privacyButton = UIButton(type: .system)
        let privacyAttributedTitle = NSAttributedString(
            string: "隱私權政策",
            attributes: [
                .font: UIFont(name: "STSongti-TC-Regular", size: 11) ?? .systemFont(ofSize: 11),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        privacyButton.setAttributedTitle(privacyAttributedTitle, for: .normal)
        privacyButton.addTarget(self, action: #selector(goToPrivacyPage), for: .touchUpInside)
        
        let andLabel = UILabel()
        andLabel.text = "&"
        andLabel.font = UIFont(name: "NotoSansTC-Regular", size: 13) ?? .systemFont(ofSize: 13)
        
        let eulaButton = UIButton(type: .system)
        let eulaAttributedTitle = NSAttributedString(
            string: "應用程式終端使用者授權協議",
            attributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        eulaButton.setAttributedTitle(eulaAttributedTitle, for: .normal)
        eulaButton.addTarget(self, action: #selector(goToEulaPage), for: .touchUpInside)
        
        linksStackView.addArrangedSubview(privacyButton)
        linksStackView.addArrangedSubview(andLabel)
        linksStackView.addArrangedSubview(eulaButton)
        
        stackView.addArrangedSubview(termsLabel)
        stackView.addArrangedSubview(linksStackView)
        
        return stackView
    }()

    // MARK: - Properties
    
    fileprivate var currentNonce: String?
    private var handle: AuthStateDidChangeListenerHandle?
    var currentUser = Auth.auth().currentUser

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAuthListener()
        showAnimation()
        loginButtonFadeIn()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.B2
        
        view.addSubview(titleLabel)
        view.addSubview(lottieAnimationView)
        view.addSubview(loginButton)
        view.addSubview(emailButton)
        view.addSubview(termsStackView)
        
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            // Lottie Animation
            lottieAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lottieAnimationView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            lottieAnimationView.widthAnchor.constraint(equalToConstant: 400),
            lottieAnimationView.heightAnchor.constraint(equalToConstant: 350),
            
            // Apple Login Button
            loginButton.heightAnchor.constraint(equalToConstant: 45),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 200),
            
            // Email Button
            emailButton.heightAnchor.constraint(equalToConstant: 45),
            emailButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emailButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            emailButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 30),
            
            // Terms StackView
            termsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            termsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            termsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15)
        ])
    }
    
    private func setupAuthListener() {
        if let user = Auth.auth().currentUser {
            print("\(user.uid) login")
            LKProgressHUD.showSuccess(text: "Already Login".localized)
        } else {
            print("not login")
            LKProgressHUD.showFailure(text: "Not Login".localized)
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                print("\(user.uid) login")
            } else {
                print("not login")
            }
            self?.currentUser = Auth.auth().currentUser
        }
    }
    
    private func showAnimation() {
        lottieAnimationView.play()
    }
    
    func loginButtonFadeIn() {
        UIView.animate(withDuration: 0.5, delay: 1.5) {
            self.loginButton.alpha = 1.0
        }
        
        UIView.animate(withDuration: 0.5, delay: 2.0) {
            self.emailButton.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    
    @objc private func goToPrivacyPage() {
        let policyVC = PolicyViewController()
        policyVC.policy = .privacy
        present(policyVC, animated: true, completion: nil)
    }
    
    @objc private func goToEulaPage() {
        let policyVC = PolicyViewController()
        policyVC.policy = .eula
        present(policyVC, animated: true, completion: nil)
    }
    
    @objc private func handleSignInWithAppleTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        currentNonce = nonce
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @objc private func popUpEmailSignIn() {
        let nextVC = SignUpViewController()
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true, completion: nil)
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = self.view.window {
            return window
        }
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
            return window
        }
        return UIApplication.shared.windows.first ?? UIWindow()
    }
    
    // MARK: - Helper Methods
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            LKProgressHUD.show(.failure("登入失敗"))
            return
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                print("Sign in error: \(error.localizedDescription)")
                LKProgressHUD.show(.failure("登入失敗，請確定網路品質"))
                return
            }

            guard let authResult = authResult else {
                LKProgressHUD.show(.failure("無法獲取用戶信息"))
                return
            }

            let uid = authResult.user.uid
            LKProgressHUD.show(.loading("Loading"))

            if authResult.additionalUserInfo?.isNewUser == true {
                self.handleNewUser(uid: uid, appleIDCredential: appleIDCredential)
            } else {
                self.handleExistingUser(uid: uid)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In Error: \(error.localizedDescription)")
        LKProgressHUD.show(.failure("登入失敗"))
    }

    private func handleNewUser(uid: String, appleIDCredential: ASAuthorizationAppleIDCredential) {
        var userInfo = UserInfo()
        userInfo.uid = uid
        userInfo.userName = appleIDCredential.fullName?.givenName ?? "User"
        userInfo.email = appleIDCredential.email

        UserManager.shared.signUpUserInfo(userInfo: userInfo) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                LKProgressHUD.show(.success("註冊成功"))
                self.fetchUserInfo(uid: uid)
            case .failure(let error):
                print("Sign up error: \(error.localizedDescription)")
                LKProgressHUD.show(.failure("註冊失敗"))
            }
        }
    }

    private func handleExistingUser(uid: String) {
        self.fetchUserInfo(uid: uid)
        LKProgressHUD.show(.success("登入成功"))
    }

    func fetchUserInfo(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userInfo):
                UserManager.shared.userInfo = userInfo
                DispatchQueue.main.async {
                    self.navigateToMainApp()
                }
            case .failure(let error):
                print("Fetch user info error: \(error.localizedDescription)")
                LKProgressHUD.show(.failure("讀取資料失敗"))
            }
        }
    }

    private func navigateToMainApp() {
        let tabBarVC = TabBarController()
        tabBarVC.modalPresentationStyle = .fullScreen
        self.present(tabBarVC, animated: true, completion: nil)
    }
}

// MARK: - Helper Functions

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

        for random in randoms {
            if remainingLength == 0 {
                continue
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}
