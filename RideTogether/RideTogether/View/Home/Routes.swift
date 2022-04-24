//
//  Routes.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import UIKit

class Routes: UICollectionViewCell {
    
    
    @IBOutlet weak var routeName: UILabel!
    
    @IBOutlet weak var routeLength: UILabel!
    
    @IBOutlet weak var rideButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell (model: Route) {
        routeName.text = model.routeName
        routeLength.text = model.routeLength.description
        
        
    }

}
