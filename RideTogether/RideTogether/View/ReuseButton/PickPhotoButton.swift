//
//  PickPhotoButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit

protocol ImagePickerDelegate {
    func presentImagePicker()
}

class ImagePikerButton: UIButton {
    
     var delegate: ImagePickerDelegate?
    
    required init?( coder aDecoder :NSCoder) {
        super .init(coder: aDecoder)
        
        addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    }
    
    @objc func pickImage(sender: UIButton) {
        
        delegate?.presentImagePicker()
        
    }
    
}
