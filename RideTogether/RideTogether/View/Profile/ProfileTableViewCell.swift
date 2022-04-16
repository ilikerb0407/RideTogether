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
        
        itemImage.contentMode = .scaleToFill
        
        itemBackground.backgroundColor = .orange
        
        itemImage.image = ProfileItemType.allCases[indexPath.item].image
    
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        itemBackground.layer.cornerRadius = itemBackground.frame.height / 2
    }
}
