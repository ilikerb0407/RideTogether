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
            tableView.backgroundColor = .white
            tableView.isScrollEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellWithNib(identifier: ProfileTableViewCell.identifier, bundle: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
}

extension ProfileViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0 :
            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
            performSegue(withIdentifier: segueId, sender: nil)
            
//        case 1 :
//            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
//            performSegue(withIdentifier: segueId, sender: nil)
            
        default :
            return
        }
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
