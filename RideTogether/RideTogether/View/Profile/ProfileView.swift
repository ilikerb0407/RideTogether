//
//  ProfileView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import Kingfisher
import UIKit

class ProfileView: UIView {
    @IBOutlet var userPhoto: UIImageView!

    @IBOutlet var userName: UITextField!

    @IBOutlet var editNameBtn: UIButton!

    func setUpProfileView(userInfo: UserInfo) {
        userName.text = userInfo.userName

        userName.textColor = .black

        userName.font = UIFont.regular(size: 24)

        userPhoto.loadImage(userInfo.pictureRef)

        userPhoto.cornerRadius = 25
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
