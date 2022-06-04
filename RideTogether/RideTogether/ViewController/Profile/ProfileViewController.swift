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
import FirebaseCrashlytics

class ProfileViewController: BaseViewController {
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    
    var userId: String { UserManager.shared.userInfo.uid }
    
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
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
        
            gView.alpha = 0.85
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.backgroundColor = .clear
            tableView.isScrollEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellWithNib(identifier: ProfileTableViewCell.identifier, bundle: nil)
        
        setUpProfileView()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }

    func updateUserInfo(name: String) {
        
        UserManager.shared.updateUserName(name: name)
    }
    
    func updateUserInfo(imageData: Data) {
        
        UserManager.shared.uploadUserPicture(imageData: imageData) { result in
            
            switch result {
                
            case .success:
                
                print("Upload user picture successfully")
                LKProgressHUD.showSuccess(text: "更新資料成功")
                
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
        20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0 :
            push(withIdentifier: "TracksViewController")
        case 1 :
            push(withIdentifier: "RecommendViewController")
        case 2 :
            
            let logOut = UIAlertAction(title: AccountActionSheet.allCases[0].rawValue, style: .default) { _ in
                self.signOut()
            }
            let removeAccount = UIAlertAction(title: AccountActionSheet.allCases[1].rawValue, style: .destructive) { _ in
                
                self.deleteAccount()
            }
            let cancel = UIAlertAction(title: AccountActionSheet.allCases[2].rawValue, style: .cancel) { _ in }
            
            showAlertAction(title: nil, message: nil, preferredStyle: .alert, actions: [logOut, removeAccount, cancel])
            
        case 3:
            push(withIdentifier: "SaveMapsViewController")
            
        default :
            return
        }
    }
    
    func deleteAccount() {
        
        let currentuser = Auth.auth().currentUser

        currentuser?.delete { error in
            
          if let error = error {

            print ("\(error)")

          } else {

              print ("delete success")
              
              UserManager.shared.deleteUserInfo(uid: currentuser!.uid)
              UserManager.shared.deleteUserSharemaps(uid: currentuser!.uid)
              UserManager.shared.deleteUserRequests(uid: currentuser!.uid)
              UserManager.shared.deleteUserFromGroup(uid: currentuser!.uid)

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
        cell.setUpCell(indexPath: indexPath)
        
        return cell
        
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
        
        // iPad specific code
        
        actionSheet.popoverPresentationController?.sourceView = self.view
                
        let xOrigin = self.view.bounds.width / 2
        
        let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)
            
        actionSheet.popoverPresentationController?.sourceRect = popoverRect
                
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        
        
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
