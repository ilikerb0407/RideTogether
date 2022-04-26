//
//  ProfileViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/9.
//

import UIKit

class ProfileViewController: BaseViewController {

    
    let items = ProfileItemType.allCases
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .orange],
                locations: [0.0, 3.0], direction: .leftSkewed)
        }
    }
    
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
        80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0 :
            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
            performSegue(withIdentifier: segueId, sender: nil)
        case 1 :
            let segueId = ProfileSegue.allCases[indexPath.row].rawValue
            performSegue(withIdentifier: segueId, sender: nil)
        case 2 :
            let alert = UIAlertController(title: "選擇", message: "帳號設定", preferredStyle: .alert)
            let logOut = UIAlertAction(title: "登出帳號", style: .default) { _ in
                
            }
            let removeAccount = UIAlertAction(title: "刪除帳號", style: .destructive) { _ in
                
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
            
            alert.addAction(logOut)
            alert.addAction(removeAccount)
            alert.addAction(cancel)
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
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
        
        cell.backgroundColor = .clear
//        cell.backgroundView = UIView()
//        cell.selectedBackgroundView = UIView()
        cell.setUpCell(indexPath: indexPath)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
        cell.backgroundColor = .clear
  
    }
    
}
