//
//  ReuseButton.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import UIKit

class PreviousPageButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .B5
        tintColor = .B2

        let image = UIImage(systemName: "chevron.left",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .light))

        setImage(image, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2

        layer.masksToBounds = true
    }
}

class NextPageButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .B2?.withAlphaComponent(0.75)

        let image = UIImage(systemName: "bicycle",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))

        setImage(image, for: .normal)

        tintColor = .B5
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2

        layer.masksToBounds = true
    }
}

class CreatGroupButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let width = UIScreen.width
        let height = UIScreen.height
        self.frame = CGRect(x: width * 0.8, y: height * 0.8, width: 70, height: 70)
        backgroundColor = .B2?.withAlphaComponent(0.75)
        setTitle("揪團", for: .normal)
        setTitleColor(.B5, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .bold)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2

        layer.masksToBounds = true
    }
}

class BottomButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        tintColor = .B5
        backgroundColor = .B2?.withAlphaComponent(0.75)
        layer.cornerRadius = 24
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50), widthAnchor.constraint(equalToConstant: 50),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class LeftButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .B5
        tintColor = .B2
        alpha = 0.5
        cornerRadius = 25
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 50),
        ])
        titleLabel?.font = UIFont.regular(size: 16)
        titleLabel?.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class TrackButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .B5
        tintColor = .B2
        alpha = 0.5
        cornerRadius = 35
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70),
            widthAnchor.constraint(equalToConstant: 70),
        ])
        titleLabel?.font = UIFont.regular(size: 16)
        titleLabel?.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class UBikeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .B2?.withAlphaComponent(0.75)

        let image = UIImage(named: "ubike2.0", in: nil,
                            with: UIImage.SymbolConfiguration(pointSize: 10, weight: .medium))

        setImage(image, for: .normal)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 50),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 12

        layer.masksToBounds = true
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

        layer.cornerRadius = frame.height / 2

        layer.masksToBounds = true
    }

    func configure() {
        backgroundColor = UIColor.hexStringToUIColor(hex: "64696F")

        let image = UIImage(systemName: "xmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))

        setImage(image, for: .normal)

        tintColor = .white
    }
}

class ImagePikerButton: UIButton {
    var delegate: ImagePickerDelegate?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    }

    @objc func pickImage(sender _: UIButton) {
        delegate?.presentImagePicker()
    }
}

class RequestButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let width = UIScreen.width
        let height = UIScreen.height
        self.frame = CGRect(x: width * 0.8, y: height * 0.6, width: 70, height: 70)

        backgroundColor = .white

        let image = UIImage(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))

        setImage(image, for: .normal)

        tintColor = .C4
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2

        layer.masksToBounds = true
    }
}

protocol ImagePickerDelegate {
    func presentImagePicker()
}
