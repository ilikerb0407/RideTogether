//
//  RecommendTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//

import UIKit
import SwiftUI

class RecommendTableViewCell: UITableViewCell {

    
    @IBOutlet weak var mapTitle: UILabel!
    
    @IBOutlet weak var mapTime: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
        self.backgroundColor = .C4
        self.contentView.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setUpCell(model : Record) {
        mapTitle.text = model.recordName
        mapTime.text = TimeFormater.preciseTime.timestampToString(time: model.createdTime)
    }
    
}
