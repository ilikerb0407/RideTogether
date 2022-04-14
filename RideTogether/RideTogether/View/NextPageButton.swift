//
//  NextPageButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import UIKit

// 下一頁的button

class NextPageButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
        
        let image = UIImage(systemName: "bicycle",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 35, weight: .medium))
        
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
