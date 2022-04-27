//
//  LoginFireBaseViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit
import FirebaseAuth
import Firebase


class LoginFireBaseViewController: UIViewController {
    
    
    @IBOutlet weak var loginEmail: UITextField!
    
    @IBOutlet weak var loginPassword: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    
    private var userInfo = UserManager.shared.userInfo
    
    @objc func loginwithFB() {
        
        
        if self.loginEmail.text == "" || self.loginPassword.text == "" {
            
            
            let alertController = UIAlertController(title: "Error", message: "Please enter an email and password.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            Auth.auth().signIn(withEmail: self.loginEmail.text!, password: self.loginPassword.text!) { [self] ( user, error) in
                
                if error == nil {
                    
                    //Print into the console if successfully logged in
                    print("You have successfully logged in")
                    if let isNewUser = user?.additionalUserInfo?.isNewUser,
                       
                       let uid = user?.user.uid {
                        
                        if isNewUser {
                            
                            self.userInfo.uid = uid
                            
                            self.userInfo.userName = "新使用者"
                            
                            UserManager.shared.signUpUserInfo(userInfo: self.userInfo) { result in
                                
                                switch result {
                                    
                                case .success:
                                    
                                    print("User Sign up successfully")
                                    
                                case .failure(let error):
                                    
                                    print("Sign up failure: \(error)")
                                }
                            }
                            
                        } else {
                            
                            UserManager.shared.fetchUserInfo(uid: uid) { result in
                                switch result {
                                    
                                case .success(let userInfo):
                                    
                                    UserManager.shared.userInfo = userInfo
                                    
                                    print("Fetch user info successfully")
                                    //
                                    guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                                        identifier: TabBarController.identifier) as? TabBarController else { return }
                                    
                                    tabbarVC.modalPresentationStyle = .fullScreen
                                    
                                    self.present(tabbarVC, animated: true, completion: nil)
                                    
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
                    
                    
                    //Go to the HomeViewController if the login is sucessful
                    
                    
                    
                } else {
                    
                    //Tells the user that there is an error and then gets firebase to tell them the error
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
                
                UserManager.shared.userInfo = userInfo
                
                print("Fetch user info successfully")
                //
                guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                    identifier: TabBarController.identifier) as? TabBarController else { return }
                
                tabbarVC.modalPresentationStyle = .fullScreen
                
                self.present(tabbarVC, animated: true, completion: nil)
                
            case .failure(let error):
                
                print("Fetch user info failure: \(error)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.addTarget(self, action: #selector(loginwithFB), for: .touchUpInside)
    }
    
    
    
}
