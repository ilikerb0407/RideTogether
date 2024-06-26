//
//  RoutesTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import UIKit

class RoutesTableViewCell: UITableViewCell {
    @IBOutlet var routeTitle: UILabel!

    @IBOutlet var routeType: UILabel!

    @IBOutlet var routelength: UILabel!

    @IBOutlet var rideBtn: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        self.backgroundColor = .clear
    }

    func setUpCell(model: Route) {
        routeTitle.text = model.routeName

        routeType.text = model.routeInfo

        routelength.text = model.routeLength
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margins = UIEdgeInsets(top: 10, left: 50, bottom: 10, right: 50)
        contentView.frame = contentView.frame.inset(by: margins)
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.borderWidth = 4
        contentView.layer.cornerRadius = 10.0
        contentView.backgroundColor = .B5
        contentView.layer.masksToBounds = true
    }
}
