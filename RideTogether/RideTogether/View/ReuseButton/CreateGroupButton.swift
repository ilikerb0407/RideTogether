//
//  CreateGroupButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit
import SwiftUI

// 下一頁的button

class CreatGroupButton: UIButton {
    
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let width = UIScreen.width
        let height = UIScreen.height
        self.frame = CGRect(x: width * 0.8, y: height * 0.8, width: 70, height: 70)
        
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        self.setTitle("揪團", for: .normal)
        self.tintColor = .B5
        
//        let image = UIImage(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
//        
//        self.setImage(image, for: .normal)
        
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

class RequestButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let width = UIScreen.width
        let height = UIScreen.height
        self.frame = CGRect(x: width * 0.8, y: height * 0.6, width: 70, height: 70)
        
        self.backgroundColor = .white
        
        let image = UIImage(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .C4
        
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

