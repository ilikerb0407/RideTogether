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
    
    @IBOutlet weak var heart: UIButton!
    
    var likes : Bool = false
    
    var sendIsLike : ((_ isSelected: Bool) ->())?
    
    @objc func heartTapped(_ sender: UIButton) {
        
//      heart.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        
        sender.isSelected = !likes
        
        likes.toggle()

    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
        
        self.backgroundColor = .clear
        
        self.contentView.backgroundColor = .clear
        
        heart.setImage(UIImage(systemName: "heart"), for: .normal)

        heart.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        
        heart.addTarget(self, action: #selector(heartTapped), for: .touchUpInside)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func setUpCell(model : Record) {
        
        mapTitle.text = model.recordName
        mapTime.text = TimeFormater.preciseTime.timestampToString(time: model.createdTime)
        
        
    }
    
}
