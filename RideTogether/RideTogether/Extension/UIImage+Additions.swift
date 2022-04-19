//
//  UIImage+Additions.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/19.
//

import UIKit

extension UIImage {
    
  static var buttonBackground: UIImage {
    let imageSideLength: CGFloat = 8
    let halfSideLength = imageSideLength / 2
    let imageFrame = CGRect(
      x: 0,
      y: 0,
      width: imageSideLength,
      height: imageSideLength
    )

    let image = UIGraphicsImageRenderer(size: imageFrame.size).image { ctx in
      ctx.cgContext.addPath(
        UIBezierPath(
          roundedRect: imageFrame,
          cornerRadius: halfSideLength
        ).cgPath
      )
      ctx.cgContext.setFillColor(UIColor.primary.cgColor)
      ctx.cgContext.fillPath()
    }

    return image.resizableImage(
      withCapInsets: UIEdgeInsets(
        top: halfSideLength,
        left: halfSideLength,
        bottom: halfSideLength,
        right: halfSideLength
      )
    )
  }
}
