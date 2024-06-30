//
//  RecommendTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//

import SwiftUI
import UIKit

class RecommendTableViewCell: UITableViewCell {
    @IBOutlet var mapTitle: UILabel!

    @IBOutlet var mapTime: UILabel!

    @IBOutlet var heart: UIButton!

    @IBOutlet var userPhoto: UIImageView!

    var likes: Bool = false

    var sendIsLike: ((_ isSelected: Bool) -> Void)?

    @objc
    func heartTapped(_ sender: UIButton) {
//      heart.setImage(UIImage(systemName: "heart.fill"), for: .normal)

        sender.isSelected = !likes

        likes.toggle()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none

        self.backgroundColor = .clear

        self.contentView.backgroundColor = .clear

        heart.setImage(UIImage(systemName: "heart"), for: .normal)

        heart.setImage(UIImage(systemName: "heart.fill"), for: .selected)

        heart.addTarget(self, action: #selector(heartTapped), for: .touchUpInside)

        // Demo 後改
        heart.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setUpCell(model: Record) {
        mapTitle.text = model.recordName

        mapTime.text = TimeFormater.preciseTime.timestampToString(time: model.createdTime)

//        guard let ref = userInfo.pictureRef else { return }
//
//        userPhoto.loadImage(ref)
//
    }
}
