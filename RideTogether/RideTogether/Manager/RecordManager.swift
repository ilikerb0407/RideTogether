//
//  RecordManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import Foundation

class RecordManager {
    var userId: String { UserManager.shared.userInfo.uid }

    var userPhoto: String { UserManager.shared.userInfo.pictureRef ?? "" }

    lazy var storage = Storage.storage()

    // 用 Overrider的方式 寫測試方法
    static let shared = RecordManager()

    func track(event: String) {
        print(">>" + event)

        if self !== RecordManager.shared {
            print(">> .... Not the RecordManger Singleton")
        }
    }

    init() { }

    lazy var storageRef = storage.reference()

    lazy var dataBase = Firestore.firestore()

    private let recordsCollection = Collection.records.rawValue

    func uploadRecord(fileName: String, fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            let data: Data = try Data(contentsOf: fileURL)

            let recordRef = storageRef.child("records").child(userId)

            let spaceRef = recordRef.child(fileName)

            spaceRef.putData(data, metadata: nil) { result in

                switch result {
                case .success:

                    spaceRef.downloadURL { result in

                        switch result {
                        case let .success(url):

                            completion(.success(url))

                            self.uploadRecordToDb(fileName: fileName, fileURL: url)

                        case let .failure(error):

                            completion(.failure(error))
                        }
                    }

                case let .failure(error):

                    completion(.failure(error))
                }
            }

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

        record.pictureRef = userPhoto

        do {
            try document.setData(from: record)

        } catch {
            print("error")
        }

        print("sucessfully")
    }

    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void) {
        let collection = dataBase.collection(recordsCollection).whereField("uid", isEqualTo: userId)

        collection.getDocuments { querySnapshot, error in

            guard let querySnapshot else {
                return
            }

            if let error {
                completion(.failure(error))
            } else {
                var records = [Record]()

                for document in querySnapshot.documents {
                    do {
                        let record = try document.data(as: Record.self, decoder: Firestore.Decoder())
                        records.append(record)

                    } catch {
                        completion(.failure(error))
                    }
                }
                records.sort { $0.createdTime.seconds > $1.createdTime.seconds }
                completion(.success(records))
            }
        }
    }

    func fetchOneRecord(completion: @escaping (Result<Record, Error>) -> Void) {
        let collection = dataBase.collection(recordsCollection).whereField("uid", isEqualTo: userId)

        collection.getDocuments { querySnapshot, error in

            guard let querySnapshot else {
                return
            }

            if let error {
                completion(.failure(error))
            } else {
                var records = Record()

                for document in querySnapshot.documents {
                    do {
                        let record = try document.data(as: Record.self, decoder: Firestore.Decoder())

                        records.recordRef.append(record.recordRef)

                    } catch {
                        completion(.failure(error))
                    }
                }

                completion(.success(records))
            }
        }
    }

    func deleteStorageRecords(fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let recordRef = storageRef.child("records").child(userId)

        let spaceRef = recordRef.child(fileName)

        spaceRef.delete { error in

            if let error {
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

        collection.getDocuments { querySnapshot, error in

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
}
