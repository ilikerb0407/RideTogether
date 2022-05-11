//
//  UserManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorageSwift

// MARK: 之後登入用得到

class UserManager {
//    
    let userId = Auth.auth().currentUser?.uid
//    
    var userInfo = UserInfo()
//    
    static let shared = UserManager()
//    
    private init() { }
//    
    lazy var storageRef = Storage.storage().reference()
//    
    lazy var dataBase = Firestore.firestore()
//    
    let usersCollection = Collection.users.rawValue
    
    let requestsCollection = Collection.requests.rawValue
    
    let shareCollection = Collection.sharedmaps.rawValue // Profile
    
    let groupsCollection = Collection.groups.rawValue
    
    func deleteUserInfo (uid: String) {
        
        let uid = userInfo.uid
        
        let document = dataBase.collection(usersCollection).document(uid)
        
        do {
            try document.delete { err in
                
                if let err = err {
                    print("Error removing document: \(err)")
                    
//                    - some : Error Domain=FIRFirestoreErrorDomain Code=7 "Missing or insufficient permissions." UserInfo={NSLocalizedDescription=Missing or insufficient permissions.}
                } else {
                    print("Document successfully removed!")
                    print ("uid ========= \(uid)")
                }
            }
        }
        
    }
    func deleteUserFromGroup(uid : String) {
       
        let docRef = dataBase.collection(groupsCollection).whereField("user_ids", arrayContains: uid).getDocuments { (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                
                print ("\(error)")
                
            } else {
                
                for document in querySnapshot.documents {
                    
                    document.reference.updateData([
                        "user_ids": FieldValue.arrayRemove([uid])
                    ])
                    
                }
            }
        }
        
    }
    
    func deleteUserRequests (uid: String) {
    
        let uid = userInfo.uid
      
        let document = dataBase.collection(requestsCollection).whereField("request_id", isEqualTo: uid ).getDocuments { (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                
                print ("\(error)")
                
            } else {
                
                for document in querySnapshot.documents {
                    
                    document.reference.delete()
                    
                }
            }
        }
    }
    
    func deleteUserSharemaps (uid: String) {
        
//        let uid = userInfo.uid
        
        let document = dataBase.collection(shareCollection).whereField("uid", isEqualTo: uid)
            
//        (lldb) po uid
//        "7FIqyPir7jV0x1oCNr6EWKDWh7r2"
            document.getDocuments { (querySnapshot, error) in
                print(querySnapshot?.count)
            
            guard let querySnapshot = querySnapshot else { return }
                
            if let error = error {
                
                print("\(error)")
                
            } else {
                
                for document in querySnapshot.documents {
                    
                    document.reference.delete()
                    
                }
            }
        }
    }
//    
    func signUpUserInfo(userInfo: UserInfo, completion: @escaping (Result<String, Error>) -> Void) {
        
        let uid = userInfo.uid
        
        let document = dataBase.collection(usersCollection).document(uid)
        
        do {
            
            try document.setData(from: userInfo)
            
        } catch {
            
            completion(.failure(error))
        }
        
        completion(.success("Success"))
    }
//    
    func fetchUserInfo(uid: String, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        
        let docRef = dataBase.collection(usersCollection).document(uid)
        
        docRef.getDocument {(document, error) in
            
            guard let document = document else { return }
            
            if let error = error {
                
                completion(.failure(error))
                
            } else {
                
                do {
                    if let userData = try document.data(as: UserInfo.self, decoder: Firestore.Decoder()) {
                        
                        completion(.success(userData))
                    }
                    
                } catch {
                    
                    completion(.failure(error))
                }
            }
        }
    }
//    
    func uploadUserPicture(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {

        let userId = userInfo.uid

        let spaceRef = storageRef.child("pictures").child(userId)

        spaceRef.putData(imageData, metadata: nil) { result in

            switch result {

            case .success(_):

                spaceRef.downloadURL { result in

                    switch result {

                    case .success(let url):

                        completion(.success(url))

                        self.updateImageToDb(fileURL: url)

                    case .failure(let error):

                        completion(.failure(error))
                    }
                }

            case .failure(let error):

                completion(.failure(error))
            }
        }
    }
    
    func updateImageToDb(fileURL: URL) {
        
        let userId = userInfo.uid
        
        let docRef = dataBase.collection(usersCollection).document(userId)
        
        userInfo.pictureRef = fileURL.absoluteString
        
        do {
            
            try docRef.setData(from: userInfo)
            
        } catch {
            
            print("error")
        }
        
        print("sucessfully")
    }
    
    func updateUserName(name: String) {
        
        userInfo.userName = name
        
        let userId = userInfo.uid
        
        let post = [UserInfo.CodingKeys.userName.rawValue: name]
        
        let docRef = dataBase.collection(usersCollection).document(userId)
        
        docRef.updateData(post) { error in
            
            if let error = error {
                
                print("Error updating document: \(error)")
                
            } else {
                
                print("User name successfully updated")
            }
        }
    }
    
    func updateUserGroupRecords(numOfGroups: Int, numOfPartners: Int) {
        
        userInfo.totalGroups = numOfGroups
        userInfo.totalFriends = numOfPartners
        
        let userId = userInfo.uid
        
        let post = [UserInfo.CodingKeys.totalGroups.rawValue: numOfGroups,
                    UserInfo.CodingKeys.totalFriends.rawValue: numOfPartners
        ]
        
        let docRef = dataBase.collection(usersCollection).document(userId)
        
        docRef.updateData(post) { error in
            
            if let error = error {
                
                print("Error updating document: \(error)")
                
            } else {
                
                print("User name successfully updated")
            }
        }
    }
//    
    func updateUserTrackLength(length: Double) {
        
        userInfo.totalLength += length
        
        let userId = userInfo.uid
        
        let post = [UserInfo.CodingKeys.totalLength.rawValue: userInfo.totalLength]
        
        let docRef = dataBase.collection(usersCollection).document(userId)
        
        docRef.updateData(post) { error in
            
            if let error = error {
                
                print("Error updating document: \(error)")
                
            } else {
                
                print("User name successfully updated")
            }
        }
    }
    
    func blockUser(blockUserId: String) {
        
        userInfo.blockList?.append(blockUserId)
        
        let userId = userInfo.uid
        
        let docRef = dataBase.collection(usersCollection).document(userId)
        
        docRef.updateData([
            "block_list": FieldValue.arrayUnion([blockUserId])
        ]) {error in
            
            if let error = error {
                
                print("Error updating document: \(error)")
                
            } else {
                
                print("Block list successfully updated")
            }
        }
    }
}
