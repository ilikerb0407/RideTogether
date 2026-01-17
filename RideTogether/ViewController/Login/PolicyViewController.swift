//
//  PolicyViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/6.
//

import UIKit
import WebKit

class PolicyViewController: BaseViewController, WKNavigationDelegate {
    var policy: PolicyType?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private lazy var webView: WKWebView = {
        let website = WKWebView()

        website.navigationDelegate = self

        return website

    }()

    private func loadURL(type: PolicyType) {
        if let url = URL(string: type.url) {
            let request = URLRequest(url: url)

            webView.load(request)
        }
    }

    private func setWebView() {
        view.stickSubView(webView)

        view.sendSubviewToBack(webView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setWebView()

        if let policyType = policy {
            loadURL(type: policyType)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.tabBar.isHidden = true
    }
}
