//
//  GPXFileManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX

/// GPX File extension
let kFileExt = ["gpx", "GPX"]


//MARK: 處理 GPX 檔案

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
    
    class func save(_ filename: String, gpxContents: String) {
        
        let fileURL: URL = self.URLForFilename(filename)
        
        GPXFileManager.saveToURL(fileURL: fileURL, gpxContents: gpxContents)
        
        RecordManager.shared.uploadRecord(fileName: filename, fileURL: fileURL) { result in
            
            switch result {
                
            case .success:
                
                uploadTrackLengthToDb(fileURL: fileURL)
               // _url : //file:///var/mobile/Containers/Data/Application/16976C4B-1C87-4E0D-B5A6-E5077D978007/D//ocuments/2022-04-10_04-21.gpx
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
    
    /// Gets the list of `.gpx` files in Documents directory ordered by modified date
    ///
    class var fileList: [GPXFileInfo] {
        var GPXFiles: [GPXFileInfo] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            // Get all files from the directory .documentsURL. Of each file get the URL (~path)
            // last modification date and file size
            if let directoryURLs = try? fileManager.contentsOfDirectory(at: documentsURL,
                includingPropertiesForKeys: [.attributeModificationDateKey, .fileSizeKey],
                options: .skipsSubdirectoryDescendants) {
                //Order files based on the date
                // This map creates a tuple (url: URL, modificationDate: String, filesize: Int)
                // and then orders it by modificationDate
                let sortedURLs = directoryURLs.map { url in
                    (url: url,
                     modificationDate: (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast,
                     fileSize: (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
                    }
                    .sorted(by: { $0.1 > $1.1 }) // sort descending modification dates
                print(sortedURLs)
                //Now we filter GPX Files
                for (url, modificationDate, fileSize) in sortedURLs {
                    if kFileExt.contains(url.pathExtension) {
                        GPXFiles.append(GPXFileInfo(fileURL: url))
                        let lastPathComponent = url.deletingPathExtension().lastPathComponent
                        print("\(modificationDate) \(modificationDate.timeAgo(numericDates: true)) \(fileSize)bytes -- \(lastPathComponent)")
                    }
                }
            }
        }
        return GPXFiles
    }
    
}
