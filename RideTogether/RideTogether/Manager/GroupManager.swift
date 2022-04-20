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

class GroupManager {
    
    
    static let shared = GroupManager()
    
    private init() {}
    
    lazy var dataBase = Firestore.firestore()
    
    private let groupCollection = Collection.groups.rawValue
    
    
    func fetchGroups(completion: @escaping (Result<[]>))
    
    
    
    
    
}
