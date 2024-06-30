/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

class RequestButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = true
    }

    private func configureButton() {
        self.frame = CGRect(x: UIScreen.width * 0.8, y: UIScreen.height * 0.6, width: 70, height: 70)
        self.backgroundColor = .white
        let image = UIImage(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        self.setImage(image, for: .normal)
        self.tintColor = .C4
    }
}
