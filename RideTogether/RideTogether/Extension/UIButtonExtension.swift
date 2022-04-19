//
//  UIButtonExtension.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit

@IBDesignable extension UIButton {
    
    @IBInspectable var CSBorderWidth: CGFloat {
        
        get {
            
            return layer.borderWidth
        }
        
        set {
            
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var CSCornerRadius: CGFloat {
        
        get {
            
            return layer.cornerRadius
        }
        
        set {
            
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var CSBorderColor: UIColor? {
        
        get {
            
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        
        set {
            
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
    }
    
    @IBInspectable override var shadowOpacity: Float {
        
        get {
            
            return layer.shadowOpacity
        }
        
        set {
            
            layer.masksToBounds = false
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable override var shadowOffset: CGSize {
        
        get {
            
            return layer.shadowOffset
        }
        
        set {
            
            layer.masksToBounds = false
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    override var shadowColor: UIColor? {
        
        get {
            
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        
        set {
            
            if let color = newValue {
                
                layer.shadowColor = color.cgColor
                
            } else {
                
                layer.shadowColor = nil
            }
        }
    }
}

@IBDesignable

public class GradientButton: UIButton {
    
    public override class var layerClass: AnyClass {
        
        CAGradientLayer.self
    }
    private var gradientLayer: CAGradientLayer {
        
        // swiftlint:disable force_cast
        layer as! CAGradientLayer
        // swiftlint:enable force_cast
    }

    @IBInspectable public var startColor: UIColor = .white {
        
        didSet {
            
            updateColors()
        }
    }
    
    @IBInspectable public var endColor: UIColor = .red {
        
        didSet {
            
            updateColors()
        }
    }

    @IBInspectable public var startPoint: CGPoint {
        
        get {
            
            gradientLayer.startPoint
        }
        
        set {
            
            gradientLayer.startPoint = newValue
        }
    }

    @IBInspectable public var endPoint: CGPoint {
        
        get {
            
            gradientLayer.endPoint
        }
        
        set {
            
            gradientLayer.endPoint = newValue
        }
    }

    public override init(frame: CGRect = .zero) {
        
        super.init(frame: frame)
        
        updateColors()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        updateColors()
    }
}

private extension GradientButton {
    
    func updateColors() {
        
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
}

extension UIButton {
    
    func applyButtonGradient(
        colors: [UIColor?],
        locations: [NSNumber]? = [0.0, 1.0],
        direction: Direction = .topToBottom) {
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.colors = colors.map { $0?.cgColor as Any }
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        gradientLayer.frame = self.bounds
        
        switch direction {
            
        case .topToBottom:
            
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            
        case .leftSkewed:
            
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        }
        
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func stylize() {
      setTitleColor(.white, for: .normal)
      setBackgroundImage(.buttonBackground, for: .normal)
      titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
      contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    }
}
