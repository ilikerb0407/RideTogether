//
//  GroupManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseStorage
import Firebase
import Accelerate

class GroupManager {
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    static let shared = GroupManager()
    
    private init() {}
    
    lazy var dataBase = Firestore.firestore()
    
    private let groupsCollection = Collection.groups.rawValue
    
    private let requestsCollection = Collection.requests.rawValue
    
    func buildTeam(group: inout Group, completion: (Result<String, Error>) -> Void) {
        
        let document = dataBase.collection(groupsCollection).document()
        
        group.groupId = document.documentID
        
        do {
            
            try document.setData(from: group)
            
        } catch {
            
            completion(.failure(error))
            
        }
        
        completion(.success("Success"))
    }
    
    func fetchGroups(completion: @escaping (Result<[Group], Error>) -> Void) {
        
        let collection = dataBase.collection(groupsCollection)
        
        collection.order(by: "date", descending: true).getDocuments { (querySnapshot, error) in
           
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                
                completion(.failure(error))
                
            } else {
                var groups = [Group]()
                
                for document in querySnapshot.documents {
                    do {
                        if var group = try document.data(as: Group.self, decoder: Firestore.Decoder()) {
                            
                            if group.date.checkIsExpired() {
                                
                                group.isExpired = true
                            } else {
                                group.isExpired = false
                            }
                            groups.append(group)
                        }
                    }
                    catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(groups))
            }
            
        }
        
    }
    
    func requestListener (completion: @escaping(Result<[Request], Error>) -> ()) -> Void {
        
        dataBase.collection(requestsCollection).whereField("host_id", isEqualTo: userId).addSnapshotListener { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else { return }
            if let error = error {
                completion(.failure(error))
            } else {
//                completion(.success(<#T##[Request]#>))
            }
        }
    }
    
    
    func updateTeam(group: Group, completion: (Result<String, Error>) -> Void) {
        
        let document = dataBase.collection(groupsCollection).document(group.groupId)
        
        do {
            
            try document.setData(from: group)
            
        } catch {
            
            completion(.failure(error))
            
        }
        
        completion(.success("Success"))
    }
    
    
    func sendRequest(request: Request, completion: (Result<String, Error>) -> Void) {
        
        let document = dataBase.collection(requestsCollection).document()
        
        do {
            
            try document.setData(from: request)
            
        } catch {
            
            completion(.failure(error))
        }
        
        completion(.success("Success"))
    }
    
    func leaveGroup(groupId: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let docRef = dataBase.collection(groupsCollection).document(groupId)
        
        docRef.updateData([
            "user_ids": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                
                print("Error updating document: \(error)")
                
            } else {
                
                print("User leave group successfully")
            }
        }
    }
    
    
    
}
