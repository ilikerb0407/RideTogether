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
import Kingfisher

class ProfileViewController: BaseViewController {
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    
    private var textInTextfield: String = ""
    
    
    @IBOutlet weak var profileView: ProfileView!
    
    @IBAction func editName(_ sender: UIButton) {
        
        if profileView.isEditting == false {
            
            profileView.isEditting.toggle()
            
        } else {
            
            if let name = profileView.userName.text {
                
                profileView.userName.text = name
                
                updateUserInfo(name: name)
            }
            
            profileView.isEditting.toggle()
        }
    }
    
    enum CameraActionSheet: String {
        
        case camera = "相機"
        case library = "圖庫"
        case cancel = "取消"
    }
    
    enum AccountActionSheet: String, CaseIterable {
        
        case signOut = "登出帳號"
        case delete = "刪除帳號"
        case cancel = "取消"
    }
    
    let items = ProfileItemType.allCases
    
    @IBAction func editPhoto(_ sender: UIButton) {
        
        showPickerController()
        
    }
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
        
        setUpProfileView()
        
        
//        UserManager.shared.deleteUserSharemaps(uid: "OtJQvsFgBkPbaTcndvKDhcs8NZF2")
//        UserManager.shared.deleteUserRequests(uid: "OtJQvsFgBkPbaTcndvKDhcs8NZF2")
//        UserManager.shared.deleteUserRequests(uid: "9aF98NFhLHQhIqalvFBmaPUgItD3")
//          UserManager.shared.deleteUserFromGroup(uid: "9aF98NFhLHQhIqalvFBmaPUgItD3")
//
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    func updateUserInfo(name: String) {
        
        UserManager.shared.updateUserName(name: name)
    }
    
    func updateUserInfo(imageData: Data) {
        
        UserManager.shared.uploadUserPicture(imageData: imageData) { result in
            
            switch result {
                
            case .success:
                
                print("Upload user picture successfully")
                
            case .failure(let error):
                
                print("Upload failure: \(error)")
            }
        }
    }
    
    // MARK: - UI Settings -
    
    func setUpProfileView() {
        
        profileView.setUpProfileView(userInfo: userInfo)
        
//        profileView.editImageButton.delegate = self
        
        profileView.userName.delegate = self
        
        profileView.userName.addTarget(
            self,
            action: #selector(self.textFieldDidChange(_:)),
            for: .editingChanged)
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
            
            
        case 3:
            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
            performSegue(withIdentifier: segueId, sender: nil)
            
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
              
              print ("delete success")
              
              UserManager.shared.deleteUserInfo(uid: user!.uid)
              UserManager.shared.deleteUserSharemaps(uid: user!.uid)
              UserManager.shared.deleteUserRequests(uid: user!.uid)
              UserManager.shared.deleteUserFromGroup(uid: user!.uid)
              
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
            print ("current user uid ======= \(firebaseAuth.currentUser?.uid)===========")
            try firebaseAuth.signOut()
            print ("sign out current user uid ======= \(firebaseAuth.currentUser?.uid)===========")
//            UserDefaults.standard.removeObject(forKey: )
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

// MARK: - TextField DataSource -

extension ProfileViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        textInTextfield = textField.text ?? ""
    }
}
// MARK: - ImagePicker Delegate -


extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func showPickerController() {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        imagePickerController.modalPresentationStyle = .fullScreen
        
        imagePickerController.allowsEditing = true
        
        let actionSheet = UIAlertController(
            title: "選擇照片來源",
            message: nil,
            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: CameraActionSheet.camera.rawValue,
            style: .default,
            handler: { _ in
                
                imagePickerController.sourceType = .camera
                
                self.present(imagePickerController, animated: true, completion: nil)
            }))
        
        actionSheet.addAction(UIAlertAction(
            title: CameraActionSheet.library.rawValue,
            style: .default,
            handler: { _ in
                
                imagePickerController.sourceType = .photoLibrary
                
                self.present(imagePickerController, animated: true, completion: nil)
            }))
        
        actionSheet.addAction(UIAlertAction(
            title: CameraActionSheet.cancel.rawValue,
            style: .cancel,
            handler: nil
        ))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        guard let image = info[.editedImage] as? UIImage else { return }
        
        guard let imageData = image.jpegData(compressionQuality: 0.1) else { return }
        
        UIView.animate(withDuration: 0.2) {
            
            self.profileView.userPhoto.image = image
            
        }
        
        updateUserInfo(imageData: imageData)
        
        dismiss(animated: true)
    }
}
