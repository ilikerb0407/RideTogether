//
//  RouteTypes.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import UIKit

class RouteTypes: UITableViewCell {

    @IBOutlet weak var routeTitle: UILabel!
    
    @IBOutlet weak var routePhoto: UIImageView!
    
    
    func setUpCell(routetitle: String, routephoto: UIImage) {
        
        routeTitle.text = routetitle
        
        routePhoto.image = routephoto
        
        self.contentMode = .scaleAspectFill
        
        self.contentView.cornerRadius = contentView.borderWidth / 2
        
        self.routePhoto.cornerRadius = 20
        
        
        
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.contentView.backgroundColor = .clear
        
        self.backgroundColor = .clear
        
        self.selectionStyle = .none
      
        
    }
    
}
