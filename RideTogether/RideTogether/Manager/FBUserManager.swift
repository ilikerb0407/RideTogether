//
//  FBUserManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorageSwift


class FBUserManger {
    
    
    let userId = Auth.auth().currentUser?.uid
//
    var userInfo = UserInfo()
//
    static let shared = FBUserManger()
//
    private init() { }
//
    lazy var storageRef = Storage.storage().reference()
//
    lazy var dataBase = Firestore.firestore()
//
    let usersCollection = Collection.users.rawValue
    
    
}
