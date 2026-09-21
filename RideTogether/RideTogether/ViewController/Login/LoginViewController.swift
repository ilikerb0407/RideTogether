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

class LoginViewController: BaseViewController, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }

    // MARK: - Class Properties -

    fileprivate var currentNonce: String?

    private var handle: AuthStateDidChangeListenerHandle?

    private var userInfo = UserManager.shared.userInfo

    private lazy var loginButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)

    // Shared with the "Sign in with Email" button below, so both buttons'
    // corner radius stay in sync from one place.
    private let signInButtonCornerRadius: CGFloat = 10

    var currentUser = Auth.auth().currentUser

    // MARK: - Views migrated from Login.storyboard
    //
    // Login.storyboard used to hold two scenes: LoginViewController's own
    // view (this section) and SignUpViewController's (see that file).
    // Everything below was previously built in Interface Builder; it's
    // reproduced here 1:1 against the storyboard's recorded frames/
    // constraints/fonts so the screen looks identical, with two
    // exceptions noted inline where a value couldn't be replicated
    // exactly (a custom font not bundled, and Apple's non-customizable
    // button font) — both are cosmetic and covered by a comment at the
    // point they occur.

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "RideTogether"
        label.font = .systemFont(ofSize: 30)
        label.textColor = .B5
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let agreementStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.text = "點擊登入鍵，即代表您同意下列\t"
        // Storyboard specified the "PingFangTC-Regular" font by name.
        // Falling back to the system font if it isn't available keeps
        // this from silently rendering with the wrong (default) size
        // if the font name ever doesn't resolve.
        label.font = UIFont(name: "PingFangTC-Regular", size: 11) ?? .systemFont(ofSize: 11)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let linksStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        return stack
    }()

    private lazy var privacyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(
            NSAttributedString(string: "隱私權政策", attributes: [
                .font: UIFont(name: "STSongti-TC-Regular", size: 11) ?? .systemFont(ofSize: 11),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]),
            for: .normal
        )
        button.addTarget(self, action: #selector(goToPrivacyPage), for: .touchUpInside)
        return button
    }()

    private let ampersandLabel: UILabel = {
        let label = UILabel()
        label.text = "&"
        label.font = UIFont(name: "NotoSansTC-Regular", size: 13) ?? .systemFont(ofSize: 13)
        return label
    }()

    private lazy var eulaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(
            NSAttributedString(string: "應用程式終端使用者授權協議", attributes: [
                // Storyboard specified `metaFont="smallSystem"`, i.e.
                // `UIFont.smallSystemFontSize` (12pt) at the system font.
                .font: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]),
            for: .normal
        )
        button.addTarget(self, action: #selector(goToEulaPage), for: .touchUpInside)
        return button
    }()

    // Was `@IBOutlet var emailbtn: UIButton!`. Its position was already
    // entirely set in code (see `loginButtonFadeIn()` below); only its
    // visual style (background/corner radius/font/title text) came from
    // the storyboard. Both are now defined in one place.
    private lazy var emailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Email", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17.5)
        button.backgroundColor = .black
        button.layer.cornerRadius = signInButtonCornerRadius
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(popUpEmailSignIn), for: .touchUpInside)
        return button
    }()

    private func setUpStoryboardMigratedViews() {
        linksStackView.addArrangedSubview(privacyButton)
        linksStackView.addArrangedSubview(ampersandLabel)
        linksStackView.addArrangedSubview(eulaButton)

        agreementStackView.addArrangedSubview(agreementLabel)
        agreementStackView.addArrangedSubview(linksStackView)

        view.addSubview(titleLabel)
        view.addSubview(agreementStackView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),

            agreementStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            agreementStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            // Storyboard pinned this to the root view's bottom, not the
            // safe area's — kept identical here.
            agreementStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
        ])
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .B2

        setUpStoryboardMigratedViews()

        setUpSignInButton()

        loginButtonFadeIn()

        if let user = Auth.auth().currentUser {
            print("\(user.uid) login")
            LKProgressHUD.showSuccess(text: "已經登入")
        } else {
            print("not login")
            LKProgressHUD.showFailure(text: "未登入")
        }

        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in

            if let user = user {
                print("\(user.uid) login")
            } else {
                print("not login")
            }

            self?.currentUser = Auth.auth().currentUser
        }

        lottie()
    }

    func lottie() {
        var waveLottieView: AnimationView = {
            let view = AnimationView(name: "bike-animation")

            view.loopMode = .loop
            view.frame = CGRect(x: UIScreen.width / 2 - 200, y: UIScreen.height / 2 - 200, width: 400, height: 350)
            view.contentMode = .scaleAspectFit
            view.play()
            self.view.addSubview(view)
            return view
        }()
    }

    // Was `@IBAction func goToPrivacyPage(_: UIButton)` / `@IBAction func
    // goToEulaPage(_: Any)`, connected to buttons via Interface Builder.
    // Now wired with `addTarget` in `privacyButton`/`eulaButton` above, so
    // no parameter is needed and `@IBAction` no longer applies.
    @objc func goToPrivacyPage() {
        let policyVC = PolicyViewController(nibName: nil, bundle: nil)

        policyVC.policy = .privacy

        present(policyVC, animated: true, completion: nil)
    }

    @objc func goToEulaPage() {
        let policyVC = PolicyViewController(nibName: nil, bundle: nil)

        policyVC.policy = .eula

        present(policyVC, animated: true, completion: nil)
    }

//      https://www.privacypolicies.com/live/38b065d0-5b0e-4b1d-a8e0-f51274f8d269

    func setUpSignInButton() {
        view.addSubview(loginButton)

        loginButton.translatesAutoresizingMaskIntoConstraints = false

        loginButton.addTarget(self, action: #selector(handleSignInWithAppleTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 45),

            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),

            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 200),
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

    @objc func popUpEmailSignIn() {
        let nextVC = SignUpViewController(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen

        present(nextVC, animated: true, completion: .none)
    }

    func loginButtonFadeIn() {
        loginButton.alpha = 0.0

        view.addSubview(emailButton)

        emailButton.alpha = 0.0

        NSLayoutConstraint.activate([
            emailButton.heightAnchor.constraint(equalToConstant: 45),

            emailButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),

            emailButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            emailButton.centerYAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 30),

        ])

        //        self.agreementStackView.alpha = 0.0

        UIView.animate(withDuration: 0.5, delay: 2) {
            self.emailButton.alpha = 1.0
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
    func authorizationController(controller _: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization)
    {
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

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)

            Auth.auth().signIn(with: credential) { authResult, error in

                if let isNewUser = authResult?.additionalUserInfo?.isNewUser,

                   let uid = authResult?.user.uid
                {
                    LKProgressHUD.show()

                    if isNewUser {
                        self.userInfo.uid = uid

                        UserManager.shared.signUpUserInfo(userInfo: self.userInfo) { result in

                            switch result {
                            case .success:

                                self.fetchUserInfo(uid: uid)

                                LKProgressHUD.showSuccess(text: "註冊成功")

                            case let .failure(error):

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
                    guard let errorCode = AuthErrorCode(rawValue: error.code) else {
                        print("登入錯誤，請稍後再試")
                        return
                    }
                    LKProgressHUD.showFailure(text: "登入失敗，請確定網路品質")
                }
            }
        }
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
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

    func fetchUserInfo(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid) { result in

            switch result {
            case let .success(userInfo):

                UserManager.shared.userInfo = userInfo

                guard let tabBarVC = UIStoryboard.main.instantiateViewController(
                    identifier: TabBarController.identifier) as? TabBarController else { return }

                tabBarVC.modalPresentationStyle = .fullScreen

                self.present(tabBarVC, animated: true, completion: nil)

            case let .failure(error):

                LKProgressHUD.showFailure(text: "讀取資料失敗")
            }
        }
    }
}
