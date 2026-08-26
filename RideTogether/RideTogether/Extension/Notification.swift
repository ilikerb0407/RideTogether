//
//  Notification.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/1.
//

import Foundation

extension Notification.Name {
    static let userInfoDidChanged = Notification.Name("userInfoDidChanged")

    static let checkGroupDidTaped = Notification.Name("checkGroupDidTaped")

    static let didUpdateBuyItemList = Notification.Name("didUpdateBuyItemList")
}

public extension NSNotification {
    static let userInfoDidChanged = Notification.Name.userInfoDidChanged

    static let checkGroupDidTaped = Notification.Name.checkGroupDidTaped
}
