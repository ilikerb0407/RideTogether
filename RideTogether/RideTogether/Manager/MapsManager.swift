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
    
    
    // MARK: 把資料放在 Storage，先用download的功能拿下來，在upload到firebase
    
    func uploadRecord(fileName: String, fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        
        do {
            
            let data: Data = try Data(contentsOf: fileURL)
            //▿ 302 bytes
            //- count : 302
            //▿ pointer : 0x000000013510ace0
            //  - pointerValue : 5185252576
            // 還未辨識userId
            //  let recordRef = storageRef.child("records").child(userId)
            let recordRef = storageRef.child("records").child("\(userId)")
            //  gs://bikeproject-59c89.appspot.com/records
            let spaceRef = recordRef.child(fileName)

            spaceRef.putData(data, metadata: nil) { result in

                switch result {

                case .success(_):

                    spaceRef.downloadURL { result in

                        switch result {

                        case .success(let url):

                            completion(.success(url))
                            // 上傳到FireBase DataBase
                            self.uploadRecordToDb(fileName: fileName, fileURL: url)

                            GPXFileManager.uploadTrackLengthToDb(fileURL: url)

                        case .failure(let error):

                            completion(.failure(error))
                        }
                    }

                case .failure(let error):

                    completion(.failure(error))
                }
            }
            
            
        } catch {
            
            print("Unable to upload data")
            
        }
    }
    
 
    
    func uploadRecordToDb(fileName: String, fileURL: URL) {
        
        let document = dataBase.collection(mapsCollection).document()
        
        var record = Record()
        
        record.uid = userId
        
        record.recordId = document.documentID
        
        record.recordName = fileName
        
        record.recordRef = fileURL.absoluteString
        
        do {
            
            try document.setData(from: record)
            
        } catch {
            
            print("error")
        }
        
        print("sucessfully")
    }
    
    
    // MARK: 直接從 firebase 拿資料 : 可以直接在firebase 輸入資料，但是太浪費時間了
    // 0424 把shareMap 改成Record
    func fetchRecords(completion: @escaping (Result<[Record],Error>) -> Void) {
        
//        let collection = dataBase.collection(recordsCollection).whereField("uid", isEqualTo: userId) 等有User 再改
        
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
    
    // saveMapsTouser
    // 按愛心之後
    func saveMapToUser(uid: String, savemaps: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let docRef = dataBase.collection(userCollection).document(uid)
        
        docRef.updateData([
            "save_maps": FieldValue.arrayUnion([savemaps])
        ]) { error in
            if let error = error {
                
                print("Error updating document: \(error)")
                
                completion(.failure(error))
                
            } else {
                
                print("Save map to User successfully")
                
                completion(.success("Success"))
            }
        }
    }
    
    // 在按下一次愛心的時候
    
    func deleteMapFromUser(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let docRef = dataBase.collection(userCollection).document(uid)
        
        docRef.updateData([
            "save_maps": FieldValue.arrayRemove([savemaps])
        ]) { error in
            if let error = error {
                
                print("Error updating document: \(error)")
                
            } else {
                
                print("User leave group successfully")
            }
        }
    }
    
   
}
