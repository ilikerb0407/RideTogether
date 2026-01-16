//
//  SignUpViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import Firebase
import FirebaseAuth
import Lottie
import UIKit

class SignUpViewController: BaseViewController {
    
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
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = .black
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .next
        textField.enablesReturnKeyAutomatically = true
        textField.layer.cornerRadius = 15
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = .black
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.enablesReturnKeyAutomatically = true
        textField.layer.cornerRadius = 15
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加显示/隐藏密码按钮
        let toggleButton = UIButton(type: .custom)
        toggleButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        toggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        toggleButton.setImage(UIImage(systemName: "eye"), for: .selected)
        toggleButton.tintColor = .gray
        toggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        rightView.addSubview(toggleButton)
        toggleButton.center = rightView.center
        
        textField.rightView = rightView
        textField.rightViewMode = .always
        
        return textField
    }()
    
    private lazy var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 15
        button.layer.borderColor = UIColor(white: 0.67, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(signUp), for: .touchUpInside)
        return button
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 15
        button.layer.borderColor = UIColor(white: 0.67, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(loginwithFB), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLottieAnimation()
        setupTextFieldDelegates()
    }
    
    private func setupTextFieldDelegates() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.B2
        
        view.addSubview(titleLabel)
        view.addSubview(lottieAnimationView)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(signUpButton)
        view.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            // Lottie Animation - 放在标题旁边
            lottieAnimationView.heightAnchor.constraint(equalToConstant: 250),
            lottieAnimationView.widthAnchor.constraint(equalToConstant: 250),
            lottieAnimationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            lottieAnimationView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            
            // Email TextField
            emailTextField.heightAnchor.constraint(equalToConstant: 45),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            emailTextField.topAnchor.constraint(equalTo: lottieAnimationView.bottomAnchor, constant: 50),
            
            // Password TextField
            passwordTextField.heightAnchor.constraint(equalToConstant: 45),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 30),
            
            // Sign Up Button
            signUpButton.heightAnchor.constraint(equalToConstant: 45),
            signUpButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            signUpButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            
            // Login Button
            loginButton.heightAnchor.constraint(equalToConstant: 45),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupLottieAnimation() {
        lottieAnimationView.play()
    }
    
    // MARK: - Actions
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        sender.isSelected = !passwordTextField.isSecureTextEntry
        
        // 保持光标位置
        if let text = passwordTextField.text {
            passwordTextField.text = ""
            passwordTextField.text = text
        }
    }
    
    @objc private func signUp() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            let alertController = UIAlertController(
                title: "Error",
                message: "Please enter your email and password",
                preferredStyle: .alert
            )
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            if let error = error {
                let alertController = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            guard let authResult = authResult else { return }

                    print("You have successfully signed up")

            let uid = authResult.user.uid

            // 创建新用户信息
                            var newUser: UserInfo = .init()
                            newUser.uid = uid
            newUser.email = authResult.user.email
                            newUser.userName = "破風手"
                            newUser.pictureRef = ""
                            newUser.saveMaps = []
                            newUser.blockList = []
                            newUser.totalLength = 0.0

            UserManager.shared.signUpUserInfo(userInfo: newUser) { [weak self] result in
                guard let self = self else { return }

                                switch result {
                                case .success:
                                    self.userInfo = newUser
                    let alertController = UIAlertController(
                        title: "Congratulations",
                        message: "Sign Up Success",
                        preferredStyle: .alert
                    )
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel) { _ in
                            self.fetchUserInfo(uid: uid)
                    }
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                case .failure(let error):
                    print("Sign up failure: \(error)")
                    let alertController = UIAlertController(
                        title: "Error",
                        message: "Sign up failed: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(defaultAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
            }
        }
    }
    
    @objc private func loginwithFB() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            let alertController = UIAlertController(
                title: "Error",
                message: "Please enter an email and password.",
                preferredStyle: .alert
            )
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            if let error = error {
                let alertController = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
                return
            }
            
            guard let authResult = authResult else { return }
            
                    print("You have successfully logged in")
            
            let uid = authResult.user.uid
            
            // 检查是否为新用户
            if authResult.additionalUserInfo?.isNewUser == true {
                var newUser = UserInfo()
                newUser.uid = uid
                newUser.userName = "新使用者"
                newUser.blockList = []
                
                UserManager.shared.signUpUserInfo(userInfo: newUser) { [weak self] result in
                    guard let self = self else { return }
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                            let alertController = UIAlertController(
                                title: "Congratulations",
                                message: "Sign Up Success",
                                preferredStyle: .alert
                            )
                            let defaultAction = UIAlertAction(title: "OK", style: .cancel) { _ in
                                self.fetchUserInfo(uid: uid)
                            }
                                        alertController.addAction(defaultAction)
                                        self.present(alertController, animated: true, completion: nil)
                                    case .failure(let error):
                                        print("Sign up failure: \(error)")
                                    }
                                }
                            }
                        } else {
                // 现有用户，获取用户信息
                UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
                    guard let self = self else { return }
                                switch result {
                                case .success(let userInfo):
                                    UserManager.shared.userInfo = userInfo
                                    print("Fetch user info successfully")
                        self.navigateToMainApp()
                                case .failure(let error):
                                    print("Fetch user info failure: \(error)")
                        LKProgressHUD.showFailure(text: "讀取使用者資料失敗")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchUserInfo(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let userInfo):
                print("userInfo: \(userInfo)")
                UserManager.shared.userInfo = userInfo
                print("Fetch user info successfully")
                self.navigateToMainApp()
                
            case .failure(let error):
                print("Fetch user info failure: \(error)")
                LKProgressHUD.showFailure(text: "讀取使用者資料失敗")
            }
        }
    }
    
    private func navigateToMainApp() {
        let tabbarVC = TabBarController()
        tabbarVC.modalPresentationStyle = .fullScreen
        present(tabbarVC, animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}
