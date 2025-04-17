//
//  GroupInfoTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/21.
//

import UIKit

class GroupInfoTableViewCell: UITableViewCell {
    @IBOutlet var hostMarker: UIImageView!

    @IBOutlet var cellView: UIView!

    @IBOutlet var groupName: UILabel!

    @IBOutlet var routeName: UILabel!

    @IBOutlet var date: UILabel!

    @IBOutlet var limitPeople: UILabel!

    @IBOutlet var time: UILabel!

    @IBOutlet var hostName: UILabel!

    @IBOutlet var isOver: UILabel!

//    (group: Group, hostname: String)

    func setUpCell(group: Group, hostname: String) {
        groupName.text = group.groupName
        routeName.text = group.routeName
        date.text = TimeFormater.dateStyle.timestampToString(time: group.date)

        time.text = TimeFormater.timeStyle.timestampToString(time: group.date)
        hostName.text = hostname

        let limit = group.limit.description
        let count = group.userIds.count
        limitPeople.text = "\(count)/\(limit)"

        let userInfo = UserManager.shared.userInfo

        if group.hostId == userInfo.uid {
            hostMarker.isHidden = false
        } else {
            hostMarker.isHidden = true
        }

        if group.isExpired == true {
            isOver.isHidden = false
            isOver.backgroundColor = .systemGray4

        } else {
            isOver.isHidden = true
            isOver.backgroundColor = .white
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let margins = UIEdgeInsets(top: 20, left: 27, bottom: 5, right: 27)
        contentView.frame = contentView.frame.inset(by: margins)
        contentView.layer.cornerRadius = 15.0
        contentView.layer.masksToBounds = true
    }
}
