//
//  MemberTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/28.
//

import UIKit

class MemberTableViewCell: UITableViewCell {
    @IBOutlet var userImage: UIImageView!

    @IBOutlet var requestNameLabel: UILabel!

    @IBOutlet var requestLabel: UILabel!

    @IBOutlet var acceptButton: UIButton!

    @IBOutlet var rejectButton: UIButton!

    @IBOutlet var viewOfBackground: UIView!

    @IBOutlet var groupNameLabel: UILabel!

    // Join Request

    func setUpCell(model: Request, userInfo: UserInfo) {
        requestNameLabel.text = userInfo.userName

        requestLabel.text = "Wants to join"

        groupNameLabel.text = "Group : \(model.groupName)"

        guard let ref = userInfo.pictureRef else {
            return
        }

        userImage.loadImage(ref)
    }

    // Check Teammate

    func setUpCell(group _: Group, userInfo: UserInfo) {
        requestLabel.isHidden = true

        acceptButton.isHidden = true

        groupNameLabel.isHidden = true

        let image = UIImage(named: "block")

        rejectButton.setImage(image, for: .normal)

        rejectButton.backgroundColor = .B5

        if userInfo.uid == UserManager.shared.userId {
            rejectButton.isHidden = true
        }

        requestNameLabel.text = userInfo.userName

        userImage.loadImage(userInfo.pictureRef)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.backgroundColor = .clear

        viewOfBackground.layer.cornerRadius = 10

        viewOfBackground.layer.masksToBounds = true

        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        acceptButton.layer.cornerRadius = acceptButton.frame.height / 2

        acceptButton.layer.masksToBounds = true

        rejectButton.layer.cornerRadius = rejectButton.frame.height / 2

        rejectButton.layer.masksToBounds = true

        userImage.cornerRadius = userImage.frame.height / 2
    }
}
