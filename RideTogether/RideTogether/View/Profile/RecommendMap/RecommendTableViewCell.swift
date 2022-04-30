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
    
    var likes : Bool = false {
        didSet {
            if likes == true {
                
                heart.setImage(UIImage(systemName: "heart.fill"), for: .selected)
                
            } else {
                
                
                heart.setImage(UIImage(systemName: "heart"), for: .normal)
            }
        }
      }
    
    
    @IBAction func chooselLike(_ sender: Any) {
        self.likes = heart.isSelected
        
        print ("like it or not  ")
        self.heart.isSelected = self.likes
        likes.toggle()
        heart.isSelected.toggle()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
        self.backgroundColor = .C4
        self.contentView.backgroundColor = .clear
        
        self.heart.isSelected = self.likes
        
//        heart.setImage(UIImage(systemName: "heart"), for: .normal)

        heart.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        
        
        
        
        
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
