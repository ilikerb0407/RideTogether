/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

class CreateGroupButton: UIButton {
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
        self.frame = CGRect(x: UIScreen.width * 0.8, y: UIScreen.height * 0.8, width: 70, height: 70)
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        self.setTitle("揪團", for: .normal)
        self.setTitleColor(.B5, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .bold)
    }
}
