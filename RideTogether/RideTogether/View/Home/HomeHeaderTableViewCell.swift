//
//  HomeHeaderTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/1.
//

import UIKit

class HomeHeaderTableViewCell: UITableViewCell {
    var lengthStartValue: Double = 0.0

    var groupsStartValue: Int = 0

    var lengthEndValue: Double = 0.0

    var groupsEndValue: Int = 0

    var lengthDiff: Double = 0.0

    var groupsDiff: Int = 0

    @IBOutlet var totalKms: UILabel!

    @IBOutlet var totalGroups: UILabel!

    @IBOutlet var userName: UILabel!

    func updateUserInfo(user: UserInfo) {
        let displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))

        displayLink.add(to: .current, forMode: .default)

        lengthEndValue = user.totalLength / 1000

        groupsEndValue = user.totalGroups

        lengthDiff = lengthEndValue - lengthStartValue

        groupsDiff = groupsEndValue - groupsStartValue

        userName.text = user.userName
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear

        self.backgroundColor = .clear

        selectionStyle = .none
    }

    @objc
    func handleUpdate() {
        let length = String(format: "%.1f", lengthStartValue)

        totalKms.text = "\(length)"

        totalGroups.text = "\(groupsStartValue)"

        lengthStartValue += 5
        groupsStartValue += 1

        if lengthStartValue > lengthEndValue {
            lengthStartValue = lengthEndValue
        }

        if groupsStartValue > groupsEndValue {
            groupsStartValue = groupsEndValue
        }
    }
}
