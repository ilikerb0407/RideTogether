/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

internal enum ButtonFactory {
    
    static func build(backgroundColor: UIColor = .clear,
                      tintColor: UIColor = .black,
                      cornerRadius: CGFloat = 0,
                      imageName: String? = nil,
                      pointSize: CGFloat = 20,
                      weight: UIImage.SymbolWeight = .regular,
                      xPoint: CGFloat = .zero,
                      yPoint: CGFloat = .zero
    ) -> UIButton {
        let button = UIButton()
        button.backgroundColor = backgroundColor
        button.tintColor = tintColor
        if let imageName = imageName {
            let image = UIImage(systemName: imageName,
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight))
            button.setImage(image, for: .normal)
        }
        button.frame = .init(x: xPoint, y: yPoint, width: pointSize, height: pointSize)
        button.layer.cornerRadius = cornerRadius
        button.layer.masksToBounds = true
        return button
    }
}

internal enum LabelFactory {
    static func build(
        text: String?,
        font: UIFont,
        backgroundColor: UIColor = .clear,
        textColor: UIColor = .placeholderText,
        textAlignment: NSTextAlignment = .center
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.textAlignment = textAlignment
        return label
    }
}
