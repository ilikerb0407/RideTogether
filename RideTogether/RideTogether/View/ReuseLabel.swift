//
//  Label.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/18.
//

import UIKit


class LeftLabel : UILabel {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.numberOfLines = 0
        self.textAlignment = .left
        self.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        self.textColor = UIColor.B5
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

