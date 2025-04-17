//
//  LabelFactory.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2025/1/21.
//

import UIKit

internal enum LabelFactory {
    static func build(text: String?,
                      numberOfLines: Int = 0,
                      font: UIFont,
                      backgroundColor: UIColor = .clear,
                      textColor: UIColor? = .placeholderText,
                      textAlignment: NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = numberOfLines
        label.font = font
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.textAlignment = textAlignment
        return label
    }
}
