//
//  SaveMaps.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/30.
//

import UIKit

class SaveMaps: UITableViewCell {
    
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var time: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        self.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(model : Record) {
        
        title.text = model.recordName
        time.text = TimeFormater.preciseTime.timestampToString(time: model.createdTime)
    }
    
    
}
