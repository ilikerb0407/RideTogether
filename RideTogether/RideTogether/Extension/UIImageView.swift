//
//  UIImageView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/27.
//

import UIKit
import Kingfisher

extension UIImageView {

    func loadImage(_ urlString: String?, placeHolder: UIImage? = UIImage(systemName: "person.crop.fill",withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .light))) {

        guard urlString != nil else { return }
        
        let url = URL(string: urlString!)

        self.kf.setImage(with: url, placeholder: placeHolder)
    }
}
