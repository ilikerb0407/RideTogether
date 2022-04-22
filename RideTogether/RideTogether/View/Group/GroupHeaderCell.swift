//
//  GroupHeaderCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/21.
//

import UIKit
import MASegmentedControl


class GroupHeaderCell: UITableViewCell {
    
    
    @IBOutlet weak var segment: UISegmentedControl! {
        didSet {
            segment.setTitle("活動中", forSegmentAt: 0)
            segment.setTitle("個人活動", forSegmentAt: 1)
        }
      
    }
    
//    @IBOutlet weak var textSegmentControl: MASegmentedControl! {
//                didSet {
//
//                    textSegmentControl.itemsWithText = true
//                    textSegmentControl.fillEqually = false
//                    textSegmentControl.roundedControl = true
//                    textSegmentControl.setSegmentedWith(items: ["活動進行中", "個人揪團紀錄"])
//                    textSegmentControl.padding = 2
//                    textSegmentControl.textColor = .black
//                    textSegmentControl.selectedTextColor = .black
//                    textSegmentControl.thumbViewColor = .C4 ?? .systemBlue
//                    textSegmentControl.titlesFont = UIFont(name: "NotoSansTC-Regular", size: 20)
//                }
//    }

    
    @IBOutlet weak var searchBar: UISearchBar! {
        
        didSet {
            self.searchBar.searchTextField.font = UIFont.regular(size: 20)
            self.searchBar.placeholder = "查詢路線"
        }
        
    }
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.backgroundColor = .clear
        
        let image = UIImage()
        
        searchBar.backgroundImage = image
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.backgroundColor = .white
        searchBar.layer.cornerRadius = 15
        searchBar.clipsToBounds = true
        
        selectionStyle = .none
        
    }

    
    
}