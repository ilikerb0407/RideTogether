//
//  MapsManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//

import Foundation
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore


class MapsManager {
    
    lazy var storage = Storage.storage()
    
    static let shared = MapsManager()
    
    private init() { }
    
    lazy var storageRef = storage.reference()
    
    lazy var dataBase = Firestore.firestore()
    
    private let mapsCollection = Collection.maps.rawValue
    
    
    
    func fetchRecords(completion: @escaping (Result<[RecommendMap],Error>) -> Void) {
        
        
        let collection = dataBase.collection(mapsCollection)
        
        collection.getDocuments { (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                completion(.failure(error))
            } else {
                
                var records = [RecommendMap]()
                
                for document in querySnapshot.documents {
                    do {
                        if let record = try document.data(as: RecommendMap.self , decoder: Firestore.Decoder()) {
                            records.append(record)
                        }
                    }
                    catch {
                        completion(.failure(error))
                    }
                }
                records.sort { $0.createdTime.seconds > $1.createdTime.seconds}
                completion(.success(records))
            }
        }
        
    }
    
    
}
