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
        
        self.backgroundColor = .white
        
        let image = UIImage(named: "hat", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
//        let image = UIImage(systemName: "hat",
//                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        
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
