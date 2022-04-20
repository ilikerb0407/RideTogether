//
//  CreateGroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit

class CreateGroupViewController: BaseViewController {
    
    
    @IBOutlet weak var sendData: UIButton! {
        didSet{
            sendData.isUserInteractionEnabled = false
            sendData.alpha = 0.6
            sendData.backgroundColor = .orange
            sendData.cornerRadius = 24
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
}
