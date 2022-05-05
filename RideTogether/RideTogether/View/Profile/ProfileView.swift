//
//  ProfileView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit
import Kingfisher


class ProfileView: UIView {

   
    @IBOutlet weak var userPhoto: UIImageView!
    
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var editNameBtn: UIButton!
    
    func setUpProfileView(userInfo: UserInfo) {
        
        userName.text = userInfo.userName
        
        userName.textColor = .black
        
        userName.font = UIFont.regular(size: 24)
        
        userPhoto.loadImage(userInfo.pictureRef)
        
    }
    
    var isEditting: Bool = false {
        
        didSet {
            
            if isEditting {
                
                editNameBtn.setImage(UIImage(systemName: "arrow.down.square"), for: .normal)
                
            } else {
                editNameBtn.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
            }
                
            UIView.animate(withDuration: 0.1) {
                
                self.userName.backgroundColor = self.isEditting ? .systemGray6 : .clear
                
                self.userName.textColor = self.isEditting ? .darkGray : .black
                
            } completion: { [self] _ in
                
                userName.isEnabled = isEditting ? true : false
                
            }
        }
    }
   
}
