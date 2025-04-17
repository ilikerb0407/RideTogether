//
//  TrackTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import FirebaseStorage
import UIKit

class TrackTableViewCell: UITableViewCell {
    @IBOutlet var trackTitle: UILabel!

    @IBOutlet var trackTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none

        self.backgroundColor = .clear
//        self.contentView.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setUpCell(model: Record) {
        trackTitle.text = model.recordName
        trackTime.text = TimeFormater.preciseTime.timestampToString(time: model.createdTime)
    }
}
