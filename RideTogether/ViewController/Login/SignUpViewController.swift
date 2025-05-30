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
    @IBOutlet var signUpEmail: UITextField!

    @IBOutlet var signUpPassword: UITextField!

    @IBOutlet var signUpButton: UIButton!

    @IBOutlet var loginButton: UIButton!

    @objc func signUp() {

        if self.signUpEmail.text == "" || self.signUpPassword.text == "" {

            let alertController = UIAlertController(title: "Error", message: "Please enter your email and password", preferredStyle: .alert)

            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)

            present(alertController, animated: true, completion: nil)

        } else {

            Auth.auth().createUser(withEmail: self.signUpEmail.text!, password: self.signUpPassword.text!) { (user, error) in

                if error == nil {

                    print("You have successfully signed up")

                    if let isNewUser = user?.additionalUserInfo?.isNewUser,

                        let uid = user?.user.uid {

                        if isNewUser {
                            var newUser: UserInfo = .init()
                            newUser.uid = uid
                            newUser.email = user?.user.email
                            newUser.userName = "破風手"
                            newUser.pictureRef = ""
                            newUser.saveMaps = []
                            newUser.blockList = []
                            newUser.totalLength = 0.0

                            UserManager.shared.signUpUserInfo(userInfo: newUser) { result in

                                switch result {

                                case .success:
                                    self.userInfo = newUser
                                    let alertController = UIAlertController(title: "Congratulations", message: "Sign Up Success", preferredStyle: .alert)

                                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                    alertController.addAction(defaultAction)

                                    self.present(alertController, animated: true, completion: nil)

                                case .failure(let error):

                                    print("Sign up failure: \(error)")
                                }
                            }
                        } else {
                            self.fetchUserInfo(uid: uid)
                        }
                    }

                } else {
                    
                        let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)

                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(defaultAction)

                        self.present(alertController, animated: true, completion: nil)
                    }
            }
        }

    }

    func fetchUserInfo (uid: String) {

        UserManager.shared.fetchUserInfo(uid: uid) { result in

            switch result {

            case .success(let userInfo):
                print("userInfo: \(userInfo)")

                UserManager.shared.userInfo = userInfo

                print("Fetch user info successfully")

                guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                    identifier: TabBarController.identifier) as? TabBarController else { return }

                tabbarVC.modalPresentationStyle = .fullScreen

                self.present(tabbarVC, animated: true, completion: nil)

            case .failure(let error):

                print("Fetch user info failure: \(error)")

                LKProgressHUD.showFailure(text: "讀取使用者資料失敗")
            }
        }
    }

    @objc func loginwithFB() {

        if self.signUpEmail.text == "" || self.signUpPassword.text == "" {

            let alertController = UIAlertController(title: "Error", message: "Please enter an email and password.", preferredStyle: .alert)

            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)

            self.present(alertController, animated: true, completion: nil)

        } else {

            Auth.auth().signIn(withEmail: self.signUpEmail.text!, password: self.signUpPassword.text!) { [self] ( user, error) in

                if error == nil {

                    // Print into the console if successfully logged in
                    print("You have successfully logged in")
                    if let isNewUser = user?.additionalUserInfo?.isNewUser,

                       let uid = user?.user.uid {

                        if isNewUser {

                            self.userInfo.uid = uid

                            self.userInfo.userName = "新使用者"

                            self.userInfo.blockList = []

                            UserManager.shared.signUpUserInfo(userInfo: self.userInfo) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                                        let alertController = UIAlertController(title: "Congratulations", message: "Sign Up Success", preferredStyle: .alert)
                                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                        alertController.addAction(defaultAction)
                                        self.present(alertController, animated: true, completion: nil)
                                    case .failure(let error):
                                        print("Sign up failure: \(error)")
                                    }
                                }
                            }
                        } else {

                            UserManager.shared.fetchUserInfo(uid: uid) { result in
                                switch result {

                                case .success(let userInfo):

                                    UserManager.shared.userInfo = userInfo

                                    fetchUserInfo(uid: uid)

                                    print("Fetch user info successfully")

                                case .failure(let error):

                                    print("Fetch user info failure: \(error)")
                                }
                            }

                            guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                                identifier: TabBarController.identifier) as? TabBarController else { return }

                            tabbarVC.modalPresentationStyle = .fullScreen

                            self.present(tabbarVC, animated: true, completion: nil)

                        }
                    }

                } else {
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)

                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)

                    self.present(alertController, animated: true, completion: nil)
                }
            }

        }
    }

    func lottie() {

        var waveLottieView: LottieAnimationView = {

            let view = LottieAnimationView(name: "bike-ride")
            view.loopMode = .loop

            self.view.addSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([

                view.heightAnchor.constraint(equalToConstant: 250),

                view.widthAnchor.constraint(equalToConstant: 250),

                view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50),

                view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40),

                view.centerYAnchor.constraint(equalTo: self.signUpEmail.topAnchor, constant: -120)
            ])
            view.contentMode = .scaleAspectFit
            view.play()

            return view
        }()

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        signUpButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginwithFB), for: .touchUpInside)

        lottie()
    }
}
