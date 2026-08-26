//
//  Routes.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import UIKit

class Routes: UICollectionViewCell {
    @IBOutlet var routeName: UILabel!

    @IBOutlet var routeLength: UILabel!

    @IBOutlet var routeInfo: UILabel!

    @IBOutlet var rideButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        backgroundColor = .B5

        contentView.backgroundColor = .clear
    }

    func setUpCell(model: Route) {
        routeName.text = model.routeName
        routeLength.text = model.routeLength
        routeInfo.text = model.routeInfo
    }
}
