//
//  NextPageButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import UIKit

class PreviousPageButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .B5
        self.tintColor = .B2
        
        let image = UIImage(systemName: "chevron.left",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .light))
        
        self.setImage(image, for: .normal)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
        
    }
}

class NextPageButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        
        let image = UIImage(systemName: "bicycle",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .B5
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
        
    }
}
class CreatGroupButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let width = UIScreen.width
        let height = UIScreen.height
        self.frame = CGRect(x: width * 0.8, y: height * 0.8, width: 70, height: 70)
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        self.setTitle("揪團", for: .normal)
        self.setTitleColor(.B5, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
    }
    
}

class BottomButton: UIButton {
    
    override init (frame: CGRect) {
        super .init(frame: frame)
        self.tintColor = .B5
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        self.layer.cornerRadius = 24
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 50),
            self.widthAnchor.constraint(equalToConstant: 50)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class LeftButton: UIButton {
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .B5
        self.tintColor = .B2
        self.alpha = 0.5
        self.cornerRadius = 25
        NSLayoutConstraint.activate([
        self.heightAnchor.constraint(equalToConstant: 50),
        self.widthAnchor.constraint(equalToConstant: 50)])
        self.titleLabel?.font = UIFont.regular(size: 16)
        self.titleLabel?.textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
class TrackButton: UIButton {
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .B5
        self.tintColor = .B2
        self.alpha = 0.5
        self.cornerRadius = 35
        NSLayoutConstraint.activate([
        self.heightAnchor.constraint(equalToConstant: 70),
        self.widthAnchor.constraint(equalToConstant: 70)])
        self.titleLabel?.font = UIFont.regular(size: 16)
        self.titleLabel?.textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class UBikeButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .B2?.withAlphaComponent(0.75)
        
        let image = UIImage(named: "ubike2.0", in: nil,
                            with: UIImage.SymbolConfiguration(pointSize: 10, weight: .medium))
        
        self.setImage(image, for: .normal)
        
        NSLayoutConstraint.activate([
        self.heightAnchor.constraint(equalToConstant: 50),
        self.widthAnchor.constraint(equalToConstant: 50)])
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 12
 
        self.layer.masksToBounds = true
    }
}

class DismissButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
    }
    
    func configure() {
        
        self.backgroundColor = UIColor.hexStringToUIColor(hex: "64696F")
        
        let image = UIImage(systemName: "xmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .white
    }
}

class ImagePikerButton: UIButton {
    
     var delegate: ImagePickerDelegate?
    
    required init?( coder aDecoder: NSCoder) {
        super .init(coder: aDecoder)
        
        addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    }
    
    @objc func pickImage(sender: UIButton) {
        
        delegate?.presentImagePicker()
        
    }
    
}

class RequestButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let width = UIScreen.width
        let height = UIScreen.height
        self.frame = CGRect(x: width * 0.8, y: height * 0.6, width: 70, height: 70)
        
        self.backgroundColor = .white
        
        let image = UIImage(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        
        self.setImage(image, for: .normal)
        
        self.tintColor = .C4
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.height / 2
        
        self.layer.masksToBounds = true
    }
    
}

protocol ImagePickerDelegate {
    func presentImagePicker()
}
