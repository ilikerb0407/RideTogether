//
//  JGProgressHUDWrapper.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/6.
//

import JGProgressHUD
import UIKit

enum HUDType {
    case success(String)

    case failure(String)
}

class LKProgressHUD {
    static let shared = LKProgressHUD()

    private init() { }

    let hud = JGProgressHUD(style: .dark)

    var view: UIView? {
        UIApplication.shared.windows.first?.rootViewController?.view
    }

    static func show(type: HUDType) {
        switch type {
        case let .success(text):
            showSuccess(text: text)
        case let .failure(text):
            showFailure(text: text)
        }
    }

    static func showSuccess(text: String = "success") {
        showOnMainThread {
            guard let view = shared.view else { return }
            shared.hud.textLabel.text = text
            shared.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
            shared.hud.show(in: view)
            shared.hud.dismiss(afterDelay: 1.5)
        }
    }

    static func showFailure(text: String = "Failure") {
        showOnMainThread {
            guard let view = shared.view else { return }
            shared.hud.textLabel.text = text
            shared.hud.indicatorView = JGProgressHUDErrorIndicatorView()
            shared.hud.show(in: view)
            shared.hud.dismiss(afterDelay: 1.5)
        }
    }

    static func show() {
        showOnMainThread {
            guard let view = shared.view else { return }
            shared.hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
            shared.hud.textLabel.text = "Loading"
            shared.hud.show(in: view)
        }
    }

    static func dismiss() {
        showOnMainThread {
            shared.hud.dismiss()
        }
    }

    private static func showOnMainThread(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
