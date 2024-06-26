//
//  RoutesCollectionViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import UIKit

class RoutesCollectionViewCell: UICollectionViewCell {
    @IBOutlet var routeName: UILabel!

    @IBOutlet var routeLength: UILabel!

    @IBOutlet var routeInfo: UILabel!

    @IBOutlet var rideButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        self.backgroundColor = .B5

        self.contentView.backgroundColor = .clear
    }

    func setUpCell(model: Route) {
        routeName.text = model.routeName
        routeLength.text = model.routeLength
        routeInfo.text = model.routeInfo
    }
}
