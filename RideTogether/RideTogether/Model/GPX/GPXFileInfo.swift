//
//  GPXFileInfo.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation

class GPXFileInfo: NSObject {

    var fileURL: URL = URL(fileURLWithPath: "")
    // swiftlint:disable force_try
    var modifiedDate: Date {
        
        return try! fileURL.resourceValues(
            forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
    }
    
    var fileName: String {
        return fileURL.deletingPathExtension().lastPathComponent
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }
}
