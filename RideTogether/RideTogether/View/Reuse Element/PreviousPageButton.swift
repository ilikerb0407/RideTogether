/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

internal class PreviousPageButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton(backgroundColor: .B5 ?? .white, tintColor: .B2 ?? .white, imageName: "chevron.left", pointSize: 40, weight: .light)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = true
    }

    private func configureButton(backgroundColor: UIColor, tintColor: UIColor, imageName: String, pointSize: CGFloat, weight: UIImage.SymbolWeight) {
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight))
        self.setImage(image, for: .normal)
    }
}
