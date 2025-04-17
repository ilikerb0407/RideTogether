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


    @IBAction
    func goToPrivacyPage(_: UIButton) {
        let policyVC = PolicyViewController()

        policyVC.policy = .privacy

        present(policyVC, animated: true, completion: nil)
    }

    @IBAction
    func goToEulaPage(_: Any) {

        let policyVC = PolicyViewController()

        policyVC.policy = .eula

        present(policyVC, animated: true, completion: nil)
    }

    // MARK: - Methods -

    @IBOutlet private(set) var emailbtn: UIButton!

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {

        return self.view.window!

    }

    // MARK: - Class Properties -

    fileprivate var currentNonce: String?

    private var handle: AuthStateDidChangeListenerHandle?

    private lazy var loginButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)

    var currentUser = Auth.auth().currentUser

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpSignInButton()

        loginButtonFadeIn()

        if let user = Auth.auth().currentUser {
            print("\(user.uid) login")
            LKProgressHUD.showSuccess(text: "Already Login".localized)
        } else {
            print("not login")
            LKProgressHUD.showFailure(text: "Not Login".localized)
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

            let view = LottieAnimationView(name: "bike-ride")

            view.loopMode = .loop
            view.frame = CGRect(x: UIScreen.width / 2 - 200, y: UIScreen.height / 2 - 200, width: 400, height: 350)
            view.contentMode = .scaleAspectFit
            view.play()
            self.view.addSubview(view)
            return view
        }()
    }

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
    }

    private func sha256(_ input: String) -> String {

        let inputData = Data(input.utf8)

        let hashedData = SHA256.hash(data: inputData)

        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    @objc func popUpEmailSignIn() {

        if let nextVC = storyboard?.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {

            self.modalPresentationStyle = .fullScreen

            self.present(nextVC, animated: true, completion: .none)
        }

    }
    
    func loginButtonFadeIn() {

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

        UIView.animate(withDuration: 0.5, delay: 2) {
            self.emailbtn.alpha = 1.0
        }

        UIView.animate(withDuration: 0.5, delay: 1.5) {

            self.loginButton.alpha = 1.0
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
        guard let tabBarVC = UIStoryboard.main.instantiateViewController(
            identifier: TabBarController.identifier) as? TabBarController else {
            LKProgressHUD.show(.failure("無法載入主頁面"))
            return
        }
        tabBarVC.modalPresentationStyle = .fullScreen
        self.present(tabBarVC, animated: true, completion: nil)
    }
}
