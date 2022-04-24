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
    
    private let groupCollection = Collection.groups.rawValue
    
    private let requestCollection = Collection.requests.rawValue
    
    func buildTeam(group: inout Group, completion: (Result<String, Error>) -> Void) {
        
        let document = dataBase.collection(groupCollection).document()
        
        group.groupId = document.documentID
        
        do {
            
            try document.setData(from: group)
            
        } catch {
            
            completion(.failure(error))
            
        }
        
        completion(.success("Success"))
    }
    
    func fetchGroups(completion: @escaping (Result<[Group], Error>) -> Void) {
        
        let collection = dataBase.collection(groupCollection)
        
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
        
        dataBase.collection(requestCollection).whereField("host_id", isEqualTo: userId).addSnapshotListener { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else { return }
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(<#T##[Request]#>))
            }
            
        }
        
    }
    
    
    
}
