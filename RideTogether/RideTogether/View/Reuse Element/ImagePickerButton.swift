/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

class ImagePickerButton: UIButton {
    var delegate: ImagePickerDelegate?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    }

    @objc private func pickImage() {
        delegate?.presentImagePicker()
    }
}

protocol ImagePickerDelegate {
    func presentImagePicker()
}

