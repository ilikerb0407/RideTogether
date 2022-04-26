//
//  ProfileViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/9.
//

import UIKit
import Firebase
import FirebaseAuth
import AVFoundation

class ProfileViewController: BaseViewController {
    
    
    enum AccountActionSheet: String, CaseIterable {
        
        case signOut = "登出帳號"
        case delete = "刪除帳號"
        case cancel = "取消"
    }
    
    let items = ProfileItemType.allCases
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .orange],
                locations: [0.0, 3.0], direction: .leftSkewed)
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.backgroundColor = .clear
            tableView.isScrollEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellWithNib(identifier: ProfileTableViewCell.identifier, bundle: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
}
extension ProfileViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0 :
            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
            performSegue(withIdentifier: segueId, sender: nil)
        case 1 :
            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
            performSegue(withIdentifier: segueId, sender: nil)
        case 2 :
            
            let logOut = UIAlertAction(title: AccountActionSheet.allCases[0].rawValue, style: .default) { _ in
                self.signOut()
            }
            let removeAccount = UIAlertAction(title: AccountActionSheet.allCases[1].rawValue, style: .destructive) { _ in
                
                self.deleteAccount()
                
                
            }
            let cancel = UIAlertAction(title: AccountActionSheet.allCases[2].rawValue, style: .cancel) { _ in }
            showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [logOut, removeAccount, cancel])
        default :
            return
        }
    }
    
    func deleteAccount() {
        
        let user = Auth.auth().currentUser

        user?.delete { error in
          if let error = error {
              
            print ("\(error)")
              
          } else {
              print ("delete succes")
              UserManager.shared.deleteUserInfo(uid: user!.uid)
              
              }
          }
        
        guard let loginVC = UIStoryboard.login.instantiateViewController(
            identifier: LoginViewController.identifier) as? LoginViewController else { return }
        
        loginVC.modalPresentationStyle = .fullScreen
        
        present(loginVC, animated: true, completion: nil)
    }
    
    func signOut() {
        
        let firebaseAuth = Auth.auth()
        
        do {
            
            try firebaseAuth.signOut()
            
        } catch let signOutError as NSError {
            
            print("Error signing out: %@", signOutError)
            
        }
        
        if Auth.auth().currentUser == nil {
            
            guard let loginVC = UIStoryboard.login.instantiateViewController(
                identifier: LoginViewController.identifier) as? LoginViewController else { return }
            
            loginVC.modalPresentationStyle = .fullScreen
            
            present(loginVC, animated: true, completion: nil)
        }
    }
    
}

extension ProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : ProfileTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.backgroundColor = .clear
        //        cell.backgroundView = UIView()
        //        cell.selectedBackgroundView = UIView()
        cell.setUpCell(indexPath: indexPath)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = .clear
        
    }
    
}
// MARK: - ImagePicker Delegate -


extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
}
