//
//  PreviousPageButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit

// 前一頁的button

class PreviousPageButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
//        self.applyButtonGradient(
//            colors: [UIColor.hexStringToUIColor(hex: "#C4E0F8"),.orange],
//            direction: .leftSkewed)
        
        let image = UIImage(named: "backbtn", in: nil, with: UIImage.SymbolConfiguration(pointSize: 40, weight: .medium))

        
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .B1
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
        
    }
}
