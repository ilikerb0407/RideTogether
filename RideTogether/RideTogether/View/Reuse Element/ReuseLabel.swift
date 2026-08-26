//
//  ReuseLabel.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/18.
//

import UIKit

class LeftLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        numberOfLines = 0
        textAlignment = .left
        font = UIFont.systemFont(ofSize: 20, weight: .regular)
        textColor = UIColor.B5
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class RightLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        textAlignment = .right
        font = UIFont.boldSystemFont(ofSize: 30)
        textColor = UIColor.B5
        text = "00:00"
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
