//
//  ButtonFactory.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2025/1/21.
//

import UIKit

internal enum ButtonFactory {
    
    static func build(backgroundColor: UIColor? = .clear,
                      tintColor: UIColor? = .black,
                      alpha: CGFloat = 1,
                      cornerRadius: CGFloat = 0,
                      title: String? = nil,
                      titleColor: UIColor? = .black,
                      titleLabelFont: UIFont? = nil,
                      imageName: String? = nil,
                      weight: UIImage.SymbolWeight = .regular,
                      pointSize: CGFloat = 20,
                      xPoint: CGFloat = .zero, yPoint: CGFloat = .zero) -> UIButton {
        let button = UIButton()
        button.backgroundColor = backgroundColor
        button.tintColor = tintColor
        button.alpha = alpha
        button.layer.cornerRadius = cornerRadius
        button.layer.masksToBounds = true
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = titleLabelFont
        if let imageName = imageName {
            let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight))
            button.setImage(image, for: .normal)
        }
        button.frame = .init(x: xPoint, y: yPoint, width: pointSize, height: pointSize)
        return button
    }
}
