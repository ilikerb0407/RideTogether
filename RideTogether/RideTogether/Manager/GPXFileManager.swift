//
//  GPXFileManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX

class GPXFileManager {
    
    class var GPXFilesFolderURL: URL {
        
         let documentsUrl =  FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask)[0] as URL
        
         return documentsUrl
     }
    
    class func URLForFilename(_ filename: String) -> URL {
        
        var fullURL = self.GPXFilesFolderURL.appendingPathComponent(filename)
        
        fullURL = fullURL.appendingPathExtension("gpx")
        
        return fullURL
    }
    
    class func saveToURL(fileURL: URL, gpxContents: String) {
        
        do {
            
            try gpxContents.write(toFile: fileURL.path, atomically: true, encoding: String.Encoding.utf8)
            
        } catch {
            
            print("can not save to URL")
        }
    }
    
    class var gpxFilesInDevice: [URL] {
        
        var files: [URL] = []
        
        let fileManager = FileManager.default
        
        let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        
        do {
            
            if let directoryURLs = try? fileManager.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.attributeModificationDateKey, .fileSizeKey],
                options: .skipsSubdirectoryDescendants) {
                
                for url in directoryURLs {
                    files.append(url)
                }
            }
        }
        
        return files
    }
    
    class func save(filename: String, gpxContents: String) {
        
        let fileURL: URL = self.URLForFilename(filename)
        
        GPXFileManager.saveToURL(fileURL: fileURL, gpxContents: gpxContents)
        
        RecordManager.shared.uploadRecord(fileName: filename, fileURL: fileURL) { result in
            
            switch result {
                
            case .success:
                
                uploadTrackLengthToDb(fileURL: fileURL)
                
                print("save to Firebase successfully")
                
                GPXFileManager.removeFileFromURL(fileURL)
                
            case .failure(let error):
                
                print("save to Firebase failure: \(error)")
            }
        }
    }
    
    class func uploadTrackLengthToDb(fileURL: URL) {
        
        let inputURL = fileURL
        
            guard let gpx = GPXParser(withURL: inputURL)?.parsedData() else { return }
        
        let length = gpx.tracksLength
        
        UserManager.shared.updateUserTrackLength(length: length)
    }
    
    class func removeFileFromURL(_ fileURL: URL) {
        
        let defaultManager = FileManager.default
        
        do {
            try defaultManager.removeItem(atPath: fileURL.path)
            
        } catch {
            print("can not remove file")
        }
    }
    
    class func removeFile(_ filename: String) {
        
        let fileURL: URL = self.URLForFilename(filename)
        
        GPXFileManager.removeFileFromURL(fileURL)
    }
}
