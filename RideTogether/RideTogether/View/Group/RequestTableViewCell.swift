//
//  RequestTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import UIKit

class RequestTableViewCell: UITableViewCell {

    @IBOutlet weak var gRouteTitle: UILabel!
    @IBOutlet weak var gTime: UILabel!
    
    @IBOutlet weak var gPeople: UILabel!
    
    @IBOutlet weak var gText: UITextView!
    
    @IBOutlet weak var gButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(model: Request) {
        gRouteTitle.text = model.groupName
        gTime.text = model.createdTime
        
    }
    
}
