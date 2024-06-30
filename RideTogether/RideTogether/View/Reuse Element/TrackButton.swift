/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

class TrackButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func configureButton() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .B5
        self.tintColor = .B2
        self.alpha = 0.5
        self.layer.cornerRadius = 35
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 70),
            self.widthAnchor.constraint(equalToConstant: 70),
        ])
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel?.textAlignment = .center
    }
}
