//
//  UIImageView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/27.
//

import UIKit
import Kingfisher

extension UIImageView {

    func loadImage(_ urlString: String?, placeHolder: UIImage? = UIImage(named: "bikeinlaunch")) {

        guard urlString != nil else { return }
        
        let url = URL(string: urlString!)

        self.kf.setImage(with: url, placeholder: placeHolder)
    }
}
