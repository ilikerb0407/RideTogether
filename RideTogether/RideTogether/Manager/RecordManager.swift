//
//  RecordManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore

class RecordManager {
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    lazy var storage = Storage.storage()
    
    static let shared = RecordManager()
    
    private init() { }
    
    lazy var storageRef = storage.reference()
    
    lazy var dataBase = Firestore.firestore()
    
    private let recordsCollection = Collection.records.rawValue
    
    
    func uploadRecord(fileName: String, fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        
        do {
            
            let data: Data = try Data(contentsOf: fileURL)
            
            let recordRef = storageRef.child("records").child(userId)
            
            let spaceRef = recordRef.child(fileName)
            
            spaceRef.putData(data, metadata: nil) { result, error in
                
                if result != nil {
                    spaceRef.downloadURL { result, error in
                        guard let url = result else { return }
                        completion(.success(url))
                        self.uploadRecordToDb(fileName: fileName, fileURL: url)
                        GPXFileManager.uploadTrackLengthToDb(fileURL: url)
                        
                        print ("url:\(url)")
                    }
                }
            }
//            spaceRef.putData(data, metadata: nil) { result in
//
//                switch result {
//
//                case .success(_):
//
//                    spaceRef.downloadURL { result in
//
//                        switch result {
//
//                        case .success(let url):
//
//                            completion(.success(url))
//
//                            self.uploadRecordToDb(fileName: fileName, fileURL: url)
//
//                            GPXFileManager.uploadTrackLengthToDb(fileURL: url)
//
//                        case .failure(let error):
//
//                            completion(.failure(error))
//                        }
//                    }
//
//                case .failure(let error):
//
//                    completion(.failure(error))
//                }
//            }
            
        } catch {
            
            print("Unable to upload data")
            
        }
    }
    
    func uploadRecordToDb(fileName: String, fileURL: URL) {
        
        let document = dataBase.collection(recordsCollection).document()
        
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
    
    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void) {
        let collection = dataBase.collection(recordsCollection).whereField("uid", isEqualTo: userId)
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
                        
                    } catch {
                        
                        completion(.failure(error))
                    }
                }
                
                records.sort { $0.createdTime.seconds < $1.createdTime.seconds }
                
                completion(.success(records))
            }
        }
    }
    
    func deleteStorageRecords(fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let recordRef = storageRef.child("records").child(userId)
        
        let spaceRef = recordRef.child(fileName)
        
        spaceRef.delete { error in
            
            if let error = error {
                
                print("\(error)")
                
                completion(.failure(error))
                
            } else {
                
                self.deleteDbRecords(fileName: fileName)
                
                completion(.success("Success"))
            }
        }
    }
    
    func deleteDbRecords(fileName: String) {
        
        let collection = dataBase.collection(recordsCollection).whereField("record_name", isEqualTo: fileName)
        
        collection.getDocuments { (querySnapshot, error) in
            
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
    
    func detectDeviceAndUpload() {
        
        let files = GPXFileManager.gpxFilesInDevice
        
        if files.count != 0 {
            
            for file in files {
                
                let fileName = (file.absoluteString as NSString).lastPathComponent.removeFileSuffix()
                
                uploadRecord(fileName: fileName, fileURL: file) { result in
                    
                    switch result {
                        
                    case .success:
                        
                        print("save to Firebase successfully")
                        
                        GPXFileManager.removeFileFromURL(file)
                        
                    case .failure(let error):
                        
                        print("save to Firebase failure: \(error)")
                    }
                }
            }
        }
    }
}

