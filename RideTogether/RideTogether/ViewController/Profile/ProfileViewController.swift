//
//  ProfileViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/9.
//

import UIKit

class ProfileViewController: BaseViewController {

    
    let items = ProfileItemType.allCases
    
    
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.backgroundColor = .clear
            tableView.isScrollEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationBar(title: "Profile")
    }
    
}

extension ProfileViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
}

extension ProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : ProfileTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(indexPath: indexPath)
        
        return cell
        
    }
    
}
