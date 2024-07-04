//
//  UIViewExtension.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit

extension UIView {
    func addBorder() {
        layer.borderWidth = 1
        layer.cornerRadius = 3
        layer.borderColor = UIColor.border.cgColor
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            guard let borderColor = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: borderColor)
        }

        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            layer.borderWidth
        }

        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            layer.cornerRadius
        }

        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable var shadowColor: UIColor? {
        get {
            guard let color = layer.shadowColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }

        set {
            guard let uiColor = newValue else {
                return
            }
            layer.shadowColor = uiColor.cgColor
        }
    }

    @IBInspectable var shadowOpacity: Float {
        get {
            layer.shadowOpacity
        }

        set {
            layer.shadowOpacity = newValue
        }
    }

    @IBInspectable var shadowOffset: CGSize {
        get {
            layer.shadowOffset
        }

        set {
            layer.shadowOffset = newValue
        }
    }

    enum Direction: Int {
        case topToBottom = 0
        case leftSkewed
        case rightSkewed
    }

    func applyGradient( // caution: removeAll is not available for UIStoryBoard VC
        colors: [UIColor?],
        locations: [NSNumber]? = [0.0, 1.0],
        direction: Direction = .topToBottom
    ) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = colors.map { $0?.cgColor as Any }
        gradientLayer.locations = locations

        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        case .leftSkewed:
            gradientLayer.startPoint = CGPoint.zero
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        case .rightSkewed:
            gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
            gradientLayer.endPoint = CGPoint.zero
        }

        self.layer.sublayers?.removeAll()
        self.layer.addSublayer(gradientLayer)
    }

    func shake() {
        let animation = CABasicAnimation(keyPath: "position")

        animation.duration = 0.15

        animation.repeatCount = 2

        animation.autoreverses = true

        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 5, y: self.center.y))

        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 5, y: self.center.y))

        self.layer.add(animation, forKey: "position")
    }

    func roundCornersTop(cornerRadius: Double) {
        self.layer.cornerRadius = CGFloat(cornerRadius)

        self.clipsToBounds = true

        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    func roundCornersWhithoutLeftTop(cornerRadius: Double) {
        self.layer.cornerRadius = CGFloat(cornerRadius)

        self.clipsToBounds = true

        self.layer.maskedCorners = [
            .layerMaxXMinYCorner,
            .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
        ]
    }

    func roundCornersWhithoutRightTop(cornerRadius: Double) {
        self.layer.cornerRadius = CGFloat(cornerRadius)

        self.clipsToBounds = true

        self.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
        ]
    }

    func roundCorners(cornerRadius: Double) {
        self.layer.cornerRadius = CGFloat(cornerRadius)

        self.clipsToBounds = true

        self.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
            .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
        ]
    }

    func stickSubView(_ objectView: UIView) {
        objectView.removeFromSuperview()

        addSubview(objectView)

        objectView.translatesAutoresizingMaskIntoConstraints = false

        objectView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        objectView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true

        objectView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true

        objectView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    class func loadFromNib<T: UIView>() -> T {
        // swiftlint:disable force_cast
        Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
        // swiftlint:enable force_cast
    }
}
