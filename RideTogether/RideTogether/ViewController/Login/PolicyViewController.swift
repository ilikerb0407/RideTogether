//
//  PolicyViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/6.
//

import UIKit
import WebKit


enum PolicyType: String {
    
    case privacy
    
    case eula
    
    var url: String {
        
        switch self {
            
        case .privacy: return "https://www.privacypolicies.com/live/38b065d0-5b0e-4b1d-a8e0-f51274f8d269"
            
        case .eula: return "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
            
        }
    }
}



class PolicyViewController: BaseViewController, WKNavigationDelegate {
    
    var policy: PolicyType?
    
    private lazy var webView : WKWebView = {
        
        let website = WKWebView()
        
        website.navigationDelegate = self
        
        return website
        
    }()
    
    // MARK: - Methods -
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start to load")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("finish to load")
    }
    
}
