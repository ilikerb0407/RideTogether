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
            
            //Alert to tell the user that there was an error because they didn't fill anything in the textfields because they didn't fill anything in
            
            let alertController = UIAlertController(title: "Error", message: "Please enter an email and password.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            Auth.auth().signIn(withEmail: self.loginEmail.text!, password: self.loginPassword.text!) { (user, error) in
                
                if error == nil {
                    
                    //Print into the console if successfully logged in
                    print("You have successfully logged in")
                    
                    // MARK: fetchUserData
                    
                    if Auth.auth().currentUser != nil {
                        
                        if let uid = Auth.auth().currentUser?.uid {
                            
                            print("----------Current User ID: \(uid)----------")
                            
                            UserManager.shared.fetchUserInfo(uid: uid) { result in
                                
                                switch result {
                                    
                                case .success(let userInfo):
                                    
                                    UserManager.shared.userInfo = userInfo
                                    
                                    guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                                        identifier: TabBarController.identifier) as? TabBarController else { return }
                                    
                                    tabbarVC.modalPresentationStyle = .fullScreen
                                    
                                    self.present(tabbarVC, animated: true, completion: nil)
                                    
                                    
                                    print("Fetch user info successfully")
                                    
                                case .failure(let error):
                                    
                                    print("Fetch user info failure: \(error)")
                                }
                            }
                        }
                        
                    } else {
                        // 初始畫面
                        guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                            identifier: TabBarController.identifier) as? TabBarController else { return }
                        
                        tabbarVC.modalPresentationStyle = .fullScreen
                        
                        self.present(tabbarVC, animated: true, completion: nil)
                        
                        
                    }
                    
//
//                    //Go to the HomeViewController if the login is sucessful
//                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController")
//                    self.present(vc!, animated: true, completion: nil)
                    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.addTarget(self, action: #selector(loginwithFB), for: .touchUpInside)
    }
    
    
    
}