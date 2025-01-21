//
//  GPXFileManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import Foundation

class GPXFileManager {
    // 使用单例模式
    static let shared = GPXFileManager()
    private init() {}
    
    // 将类属性改为实例属性
    var gpxFilesFolderURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }
    
    // 添加错误处理
    enum GPXFileError: Error {
        case saveError
        case removeError
        case parseError
    }
    
    // 重构方法为实例方法
    func urlForFilename(_ filename: String) -> URL {
        gpxFilesFolderURL
            .appendingPathComponent(filename)
            .appendingPathExtension("gpx")
    }
    
    func saveToURL(fileURL: URL, gpxContents: String) throws {
        do {
            try gpxContents.write(toFile: fileURL.path, atomically: true, encoding: .utf8)
        } catch {
            throw GPXFileError.saveError
        }
    }
    
    func save(_ filename: String, gpxContents: String) {
        let fileURL = urlForFilename(filename)
        
        do {
            try saveToURL(fileURL: fileURL, gpxContents: gpxContents)
            
            RecordManager.shared.uploadRecord(fileName: filename, fileURL: fileURL) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.uploadTrackLengthToDb(fileURL: fileURL)
                    print("save to Firebase successfully")
                    try? self.removeFileFromURL(fileURL)
                    LKProgressHUD.show(.success("儲存成功"))
                    
                case let .failure(error):
                    print("save to Firebase failure: \(error)")
                }
            }
        } catch {
            print("Failed to save file: \(error)")
        }
    }
    
    func uploadTrackLengthToDb(fileURL: URL) {
        let inputURL = fileURL

        guard let gpx = GPXParser(withURL: inputURL)?.parsedData() else {
            return
        }

        let length = gpx.tracksLength

        UserManager.shared.updateUserTrackLength(length: length)
    }

    func removeFileFromURL(_ fileURL: URL) {
        let defaultManager = FileManager.default

        do {
            try defaultManager.removeItem(atPath: fileURL.path)

        } catch {
            print("can not remove file")
        }
    }

    func removeFile(_ filename: String) {
        let fileURL: URL = self.urlForFilename(filename)

        GPXFileManager.shared.removeFileFromURL(fileURL)
    }
}
