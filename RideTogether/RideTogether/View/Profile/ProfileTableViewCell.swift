//
//  ProfileTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

   
    @IBOutlet weak var itemImage : UIImageView!
    
    @IBOutlet weak var itemTitle : UILabel!
    
    @IBOutlet weak var itemBackground : UIView!
    
    func setUpCell(indexPath: IndexPath) {
        
        itemTitle.text = ProfileItemType.allCases[indexPath.item].title
        
        itemImage.contentMode = .scaleAspectFit
        
        itemBackground.backgroundColor = ProfileItemType.allCases[indexPath.row].backgroundColor
        
        itemImage.image = ProfileItemType.allCases[indexPath.item].image
    
        
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectionStyle = .none
        
        contentView.backgroundColor = .clear
        
        self.backgroundColor = .B2
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        itemBackground.layer.cornerRadius = 20
        
    }
}
