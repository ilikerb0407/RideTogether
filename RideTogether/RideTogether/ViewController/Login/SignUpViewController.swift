//
//  SignUpViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//
//  This used to call Auth.auth() directly and duplicate the "is this a
//  new or returning user" branching logic separately for sign-up and
//  login, with the two copies drifting apart (see SignUpViewModel.swift's
//  header comment for the bugs that caused, including a real race
//  condition). Both flows now go through SignUpViewModel; this
//  ViewController only validates nothing's visibly empty before calling
//  in, and reacts to the result by showing an alert or presenting the
//  tab bar.
//
//  Also renamed `loginwithFB()` to `logIn()` — the original name was
//  misleading: this method has never done anything with Facebook, it's
//  plain email/password sign-in. Confirmed safe to rename: it's wired via
//  `addTarget` in code, not connected through any Storyboard/XIB.

import Lottie
import UIKit

class SignUpViewController: BaseViewController {
    // Injected with a default so existing instantiation sites (from
    // Storyboard, via `init?(coder:)`) don't need to change, while tests
    // can substitute a ViewModel wired with a fake AuthProviding and
    // MockUserManager.
    var viewModel = SignUpViewModel()

    // MARK: - Views migrated from Login.storyboard's SignUpViewController
    // scene. Reproduced 1:1 against the storyboard's recorded frames/
    // constraints/fonts. Border-related userDefinedRuntimeAttributes with
    // borderWidth=0 in the original are skipped below (a zero-width
    // border is never visible, regardless of its color, so setting
    // `layer.borderColor` would have had no visible effect there either).

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "RideTogether"
        label.font = .systemFont(ofSize: 30)
        label.textColor = .B5
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var signUpEmail: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = .black
        textField.layer.cornerRadius = 15
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var signUpPassword: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = .black
        textField.isSecureTextEntry = true
        textField.layer.cornerRadius = 15
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 15
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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(logIn), for: .touchUpInside)
        return button
    }()

    private func setUpStoryboardMigratedViews() {
        view.backgroundColor = .B2

        view.addSubview(titleLabel)
        view.addSubview(signUpEmail)
        view.addSubview(signUpPassword)
        view.addSubview(signUpButton)
        view.addSubview(loginButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),

            signUpEmail.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            signUpEmail.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            signUpEmail.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 250),
            signUpEmail.heightAnchor.constraint(equalToConstant: 45),

            signUpPassword.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            signUpPassword.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            signUpPassword.topAnchor.constraint(equalTo: signUpEmail.bottomAnchor, constant: 30),
            signUpPassword.heightAnchor.constraint(equalToConstant: 45),

            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            signUpButton.topAnchor.constraint(equalTo: signUpPassword.bottomAnchor, constant: 20),
            signUpButton.widthAnchor.constraint(equalToConstant: 100),
            signUpButton.heightAnchor.constraint(equalToConstant: 45),

            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80),
            loginButton.topAnchor.constraint(equalTo: signUpPassword.bottomAnchor, constant: 20),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
            loginButton.heightAnchor.constraint(equalToConstant: 45),
        ])
    }

    @objc func signUp() {
        viewModel.signUp(email: signUpEmail.text, password: signUpPassword.text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.handle(result: result, successMessage: "Sign Up Success")
            }
        }
    }

    @objc func logIn() {
        viewModel.logIn(email: signUpEmail.text, password: signUpPassword.text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.handle(result: result, successMessage: nil)
            }
        }
    }

    private func handle(result: Result<SignUpFlowResult, Error>, successMessage: String?) {
        switch result {
        case .success(.newUserCreated):
            if let successMessage = successMessage {
                showOKAlert(title: "Congratulations", message: successMessage)
            } else {
                presentTabBar()
            }

        case .success(.existingUserFetched):
            presentTabBar()

        case let .failure(SignUpViewModelError.missingCredentials):
            showOKAlert(title: "Error", message: "Please enter your email and password")

        case let .failure(error):
            showOKAlert(title: "Error", message: error.localizedDescription)
        }
    }

    private func presentTabBar() {
        guard let tabbarVC = UIStoryboard.main.instantiateViewController(
            identifier: TabBarController.identifier) as? TabBarController else { return }

        tabbarVC.modalPresentationStyle = .fullScreen

        present(tabbarVC, animated: true, completion: nil)
    }

    private func showOKAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func lottie() {
        let waveLottieView: AnimationView = {
            let view = AnimationView(name: "bike-animation")
            view.loopMode = .loop
            self.view.addSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: 250),

                view.widthAnchor.constraint(equalToConstant: 250),

                view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50),

                view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40),

                view.centerYAnchor.constraint(equalTo: self.signUpEmail.topAnchor, constant: -120),
            ])
            view.contentMode = .scaleAspectFit
            view.play()

            return view
        }()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpStoryboardMigratedViews()

        lottie()
    }
}
