//
//  UICollectionView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import Foundation
import UIKit

extension UICollectionView {

    func lk_registerCellWithNib(identifier: String, bundle: Bundle?) {

        let nib = UINib(nibName: identifier, bundle: bundle)

        register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    func dequeueCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        // swiftlint:disable force_cast
    return self.dequeueReusableCell(withReuseIdentifier: "\(T.self)", for: indexPath) as! T
        // swiftlint:enable force_cast
    }
}
