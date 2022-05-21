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

// MARK:  準備改成線上地圖
// MARK:  Offline Map 的架構

class MapsManager {
    
    lazy var storage = Storage.storage()
    
    static let shared = MapsManager()
    
    private init() { }
    
    lazy var storageRef = storage.reference()
    
    lazy var dataBase = Firestore.firestore()
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    var savemaps: [String] {UserManager.shared.userInfo.saveMaps ?? [""]}
    
    private let mapsCollection = Collection.maps.rawValue // 離線地圖
    
    private let routeCollection = Collection.routes.rawValue // Home
    
    private let shareCollection = Collection.sharedmaps.rawValue // Profile
    
    private let saveCollection = Collection.savemaps.rawValue // Profile
    
    private let userCollection = Collection.users.rawValue // Profile
    
    
    func fetchRecords(completion: @escaping  (Result<[Record],Error>) -> Void){
        
        let collection = dataBase.collection(shareCollection)
        collection.getDocuments { (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                completion(.failure(error))
            } else {
                
                var records = [Record]()
                
                for document in querySnapshot.documents {
                    do {
                        if let record = try document.data(as: Record.self, decoder: Firestore.Decoder()) {
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
    
    func fetchRoutes(completion: @escaping (Result<[Route], Error>) -> Void ) {
        
        let collection = dataBase.collection(routeCollection)
        
        collection.getDocuments{ (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                completion(.failure(error))
            } else {
                var routes = [Route]()
                for document in querySnapshot.documents {
                    do {
                        if let route = try document.data(as: Route.self, decoder: Firestore.Decoder()) {
                            routes.append(route)
                        }
                    }
                    catch {
                        completion(.failure(error))
                    }
                }
                routes.sort { $0.createdTime.seconds > $1.createdTime.seconds }
                
                completion(.success(routes))
            }
            
        }
        
    }
    
    func fetchSavemaps (completion: @escaping (Result<[Record],Error>) -> Void) {
        
        let collection = dataBase.collection(saveCollection).whereField("uid", isEqualTo: userId)
                collection.getDocuments { (querySnapshot, error) in
                    
                    guard let querySnapshot = querySnapshot else { return }
                    
                    if let error = error {
                        
                        completion(.failure(error))
                    } else {
                        
                        var records = [Record]()
                        
                        for document in querySnapshot.documents {
                            do {
                                if let record = try document.data(as: Record.self , decoder: Firestore.Decoder()) {
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
    
    func deleteDbRecords(recordId: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let collection = dataBase.collection(saveCollection).whereField("record_id", isEqualTo: recordId)
        
        collection.getDocuments { (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else { return }
            
            if let error = error {
                
                print("\(error)")
                
                completion(.failure(error))
                
            } else {
                
                for document in querySnapshot.documents {
                    
                    document.reference.delete()
                    
                    completion(.success(""))
                    
                }
            }
        }
    }
   
}
