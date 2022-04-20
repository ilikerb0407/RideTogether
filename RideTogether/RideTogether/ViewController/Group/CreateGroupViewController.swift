//
//  CreateGroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit

class CreateGroupViewController: BaseViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showUpView()
        
    }
    
    func showUpView() {
        
        let newView = UIView(frame: CGRect(x: 0, y: 200, width: self.view.frame.width, height: 400))
        newView.backgroundColor = .orange
        newView.layer.cornerRadius = 20
        
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(newView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
        
        
        func setUpLabel() {
            newView.addSubview(titleLabel)
           
        }
        
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        dismiss(animated: true, completion: nil)
    }

    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.regular(size: 20)
        label.textColor = UIColor.black
        return label
    }()
    
    var sendButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send Invitation", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 16)
        button.titleLabel?.textAlignment = .center
        button.alpha = 0.5
        return button
    }()
    
    
    
}
