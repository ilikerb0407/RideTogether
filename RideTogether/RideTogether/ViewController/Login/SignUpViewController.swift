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
    @IBOutlet var signUpEmail: UITextField!

    @IBOutlet var signUpPassword: UITextField!

    @IBOutlet var signUpButton: UIButton!

    @IBOutlet var loginButton: UIButton!

    // Injected with a default so existing instantiation sites (from
    // Storyboard, via `init?(coder:)`) don't need to change, while tests
    // can substitute a ViewModel wired with a fake AuthProviding and
    // MockUserManager.
    var viewModel = SignUpViewModel()

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

        signUpButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(logIn), for: .touchUpInside)

        lottie()
    }
}
