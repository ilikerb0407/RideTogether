//
//  NextPageButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import UIKit
import SwiftUI

// 下一頁的button

class NextPageButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        
        let image = UIImage(systemName: "bicycle",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .B5
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

class NormalButton: UIButton {
    
    override init (frame: CGRect) {
        super .init(frame: frame)
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        
        
    }
    
    
    
}




class UBikeButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        
        let image = UIImage(named: "ubike2.0", in: nil,
                            with: UIImage.SymbolConfiguration(pointSize: 10, weight: .medium))
        
        self.setImage(image, for: .normal)
 
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 12
        
        self.layer.masksToBounds = true
    }
}


class DismissButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
    }
    
    func configure() {
        
        self.backgroundColor = UIColor.hexStringToUIColor(hex: "64696F")
        
        let image = UIImage(systemName: "xmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .white
    }
}
