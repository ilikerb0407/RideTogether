//
//  GPXFileInfo.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation


class GPXFileInfo: NSObject {
    
    /// file URL
    var fileURL: URL = URL(fileURLWithPath: "")
    
    /// Last time the file was modified
    var modifiedDate: Date {
        // swiftlint:disable force_try
        return try! fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
    }
    
    var modifiedDatetimeAgo: String {
        return modifiedDate.timeAgo(numericDates: true)
    }
    
    var fileSize: Int {
        // swiftlint:disable force_try
        return try! fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
    

    var fileSizeHumanised: String {
        return fileSize.asFileSize()
    }
    
    var fileName: String {
        return fileURL.deletingPathExtension().lastPathComponent
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }
    
}

extension Int {
    
    // Returns the integer as file size humanized (for instance: 1024 -> "1 KB" )
    func asFileSize() -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        let string = bcf.string(fromByteCount: Int64(self))
        //print("formatted result: \(string)")
        return string
    }
}

