//
//  SignUpViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: BaseViewController {
    
    @IBOutlet weak var signUpEmail: UITextField!
    
    @IBOutlet weak var signUpPassword: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    private var userInfo = UserManager.shared.userInfo
    
    
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
                            
                            self.userInfo.uid = uid
                            
                            self.userInfo.userName = user?.user.displayName ?? "新使用者"
                            
                            UserManager.shared.signUpUserInfo(userInfo: self.userInfo) { result in
                                
                                switch result {
                                    
                                case .success:
                                    
                                    self.fetchUserInfo(uid: uid)
                                    
                                    print("User Sign up successfully")
                                    
                                case .failure(let error):
                                    
                                    print("Sign up failure: \(error)")
                                }
                            }
                        } else {
                            
                            self.fetchUserInfo(uid: uid)
                            
                        }
                    } }
                else {
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
        
        signUpButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)
        
    }
    
}
