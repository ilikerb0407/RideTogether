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
    
    @IBOutlet weak var routeInfo: UILabel!
    
    @IBOutlet weak var rideButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = .C1
        
        self.contentView.backgroundColor = .clear
    }
    
    func setUpCell (model: Route) {
        
        routeName.text = model.routeName
        routeLength.text = model.routeLength
        routeInfo.text = model.routeInfo
        
    }

}
