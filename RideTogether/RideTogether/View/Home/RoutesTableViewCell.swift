//
//  RoutesTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import UIKit

class RoutesTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var routeTitle: UILabel!
    
    @IBOutlet weak var routeType: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.backgroundColor = .C4
        self.contentView.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(model : Route) {
        routeTitle.text = model.routeName
        routeType.text = model.routeInfo
    }
    
}
