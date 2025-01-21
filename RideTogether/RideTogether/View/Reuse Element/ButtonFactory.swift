//
//  ButtonFactory.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2025/1/21.
//

import UIKit

internal enum ButtonFactory {
    
    static func build(backgroundColor: UIColor? = .clear,
                      tintColor: UIColor = .black,
                      cornerRadius: CGFloat = 0,
                      imageName: String? = nil,
                      pointSize: CGFloat = 20,
                      weight: UIImage.SymbolWeight = .regular,
                      xPoint: CGFloat = .zero, yPoint: CGFloat = .zero) -> UIButton {
        let button = UIButton()
        button.backgroundColor = backgroundColor
        button.tintColor = tintColor
        if let imageName = imageName {
            let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight))
            button.setImage(image, for: .normal)
        }
        button.frame = .init(x: xPoint, y: yPoint, width: pointSize, height: pointSize)
        button.layer.cornerRadius = cornerRadius
        button.layer.masksToBounds = true
        return button
    }
}
