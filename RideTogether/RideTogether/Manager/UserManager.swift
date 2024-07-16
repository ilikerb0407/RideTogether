//
//  UserManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import UIKit

internal class UserManager {
    let userId = Auth.auth().currentUser?.uid

    var userInfo = UserInfo()

    static let shared = UserManager()

    private init() { }

    lazy var storageRef = Storage.storage().reference()

    lazy var dataBase = Firestore.firestore()

    let usersCollection = Collection.users.rawValue

    let requestsCollection = Collection.requests.rawValue

    let shareCollection = Collection.sharedmaps.rawValue

    let groupsCollection = Collection.groups.rawValue

    func deleteUserInfo(uid _: String) {
        let uid = userInfo.uid

        let document = dataBase.collection(usersCollection).document(uid)

        do {
            document.delete { err in
                if let err {
                    LKProgressHUD.show(.failure("刪除失敗"))
                } else {
                    LKProgressHUD.show(.success("刪除成功"))
                }
            }
        }
    }

    func deleteUserFromGroup(uid: String) {
        dataBase.collection(groupsCollection).whereField("user_ids", arrayContains: uid).getDocuments { querySnapshot, error in

            guard let querySnapshot else {
                return
            }

            if error != nil {
                LKProgressHUD.show(.failure("刪除失敗"))

            } else {
                for document in querySnapshot.documents {
                    document.reference.updateData([
                        "user_ids": FieldValue.arrayRemove([uid]),
                    ])
                }
            }
        }
    }

    func deleteUserRequests(uid _: String) {
        let uid = userInfo.uid

        dataBase.collection(requestsCollection).whereField("request_id", isEqualTo: uid).getDocuments { querySnapshot, error in

            guard let querySnapshot else {
                return
            }

            if error != nil {
                LKProgressHUD.show(.failure("刪除失敗"))

            } else {
                for document in querySnapshot.documents {
                    document.reference.delete()
                }
            }
        }
    }

    func deleteUserSharemaps(uid: String) {
        let document = dataBase.collection(shareCollection).whereField("uid", isEqualTo: uid)

        document.getDocuments { querySnapshot, error in

            guard let querySnapshot else {
                return
            }

            if let error {
                print("\(error)")

            } else {
                for document in querySnapshot.documents {
                    document.reference.delete()
                }
            }
        }
    }

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

    func fetchUserInfo(uid: String, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        let docRef = dataBase.collection(usersCollection).document(uid)

        docRef.getDocument { document, error in

            guard let document else {
                return
            }

            if let error {
                completion(.failure(error))

            } else {
                do {
                    let userData = try document.data(as: UserInfo.self, decoder: Firestore.Decoder())
                    completion(.success(userData))

                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func uploadUserPicture(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let userId = userInfo.uid

        let spaceRef = storageRef.child("pictures").child(userId)

        spaceRef.putData(imageData, metadata: nil) { result in

            switch result {
            case .success:

                spaceRef.downloadURL { result in

                    switch result {
                    case let .success(url):

                        completion(.success(url))

                        self.updateImageToDb(fileURL: url)

                    case let .failure(error):

                        completion(.failure(error))
                    }
                }

            case let .failure(error):

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

            if let error {
                print("Error updating document: \(error)")

            } else {
                print("User name successfully updated")
            }
        }
    }

    func updateUserGroupRecords(numOfGroups: Int, numOfPartners: Int) {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            print("Error: User ID is empty or nil")
            return
        }

        let docRef = dataBase.collection(usersCollection).document(uid)

        let data: [String: Any] = [
            "total_groups": numOfGroups,
            "total_friends": numOfPartners
        ]

        docRef.updateData(data) { error in
            if let error = error {
                print("Error updating document: \(error)")
                if let firestoreError = error as? FirestoreErrorCode {
                    switch firestoreError.code {
                    case .notFound:
                        print("Document not found. Creating a new one.")
                        docRef.setData(data) { error in
                            if let error = error {
                                print("Error creating document: \(error)")
                            } else {
                                print("New document created successfully")
                            }
                        }
                    default:
                        print("Firestore error: \(firestoreError.localizedDescription)")
                    }
                }
            } else {
                print("User group records successfully updated")
            }
        }
    }

    func updateUserTrackLength(length: Double) {
        userInfo.totalLength += length

        let userId = userInfo.uid

        let post = [UserInfo.CodingKeys.totalLength.rawValue: userInfo.totalLength]

        let docRef = dataBase.collection(usersCollection).document(userId)

        docRef.updateData(post) { error in

            if let error {
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
            "block_list": FieldValue.arrayUnion([blockUserId]),
        ]) { error in

            if let error {
                print("Error updating document: \(error)")

                LKProgressHUD.show(.failure("無法封鎖，因為不是使用者提供的路線"))

            } else {
                print("Block list successfully updated")
                LKProgressHUD.show(.success("封鎖成功，請回到首頁"))
            }
        }
    }
}
