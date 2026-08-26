//
//  RouteTypes.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import UIKit

class RouteTypes: UITableViewCell {
    @IBOutlet var routeTitle: UILabel!

    @IBOutlet var routePhoto: UIImageView!

    func setUpCell(routetitle: String, routephoto: UIImage) {
        routeTitle.text = routetitle

        routePhoto.image = routephoto

        contentMode = .scaleAspectFill

        contentView.cornerRadius = contentView.borderWidth / 2

        routePhoto.cornerRadius = 20
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear

        backgroundColor = .clear

        selectionStyle = .none
    }
}
