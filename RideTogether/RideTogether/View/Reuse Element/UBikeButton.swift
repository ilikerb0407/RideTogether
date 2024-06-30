/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

class UBikeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
    }

    private func configureButton() {
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(named: "ubike2.0", in: nil, with: UIImage.SymbolConfiguration(pointSize: 10, weight: .medium))
        self.setImage(image, for: .normal)
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 50),
            self.widthAnchor.constraint(equalToConstant: 50),
        ])
    }
}
