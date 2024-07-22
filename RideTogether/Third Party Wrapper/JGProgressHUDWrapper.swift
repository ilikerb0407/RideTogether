//
//  JGProgressHUDWrapper.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/6.
//

import JGProgressHUD
import UIKit

final class LKProgressHUD {
    static let shared = LKProgressHUD()

    enum HUDType {
        case success(String)
        case failure(String)
        case loading(String)
    }

    private init() {}

    private let hud = JGProgressHUD(style: .dark)

    private var view: UIView? {
        UIApplication.shared.windows.first?.rootViewController?.view
    }

    static func show(_ type: HUDType) {
        switch type {
        case .success(let text):
            showSuccess(text: text)
        case .failure(let text):
            showFailure(text: text)
        case .loading(let text):
            showLoading(text: text)
        }
    }

    static func dismiss() {
        showOnMainThread {
            shared.hud.dismiss()
        }
    }

    static func showSuccess(text: String) {
        showHUD(text: text, indicatorView: JGProgressHUDSuccessIndicatorView())
    }

    static func showFailure(text: String) {
        showHUD(text: text, indicatorView: JGProgressHUDErrorIndicatorView())
    }

    private static func showLoading(text: String) {
        showHUD(text: text, indicatorView: JGProgressHUDIndeterminateIndicatorView())
    }

    private static func showHUD(text: String, indicatorView: JGProgressHUDIndicatorView) {
        showOnMainThread {
            guard let view = shared.view else { return }
            shared.hud.textLabel.text = text
            shared.hud.indicatorView = indicatorView
            shared.hud.show(in: view)

            if !(indicatorView is JGProgressHUDIndeterminateIndicatorView) {
                shared.hud.dismiss(afterDelay: 1.5)
            }
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
