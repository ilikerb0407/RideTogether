//
//  GroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit

class GroupViewController: BaseViewController {

    //MARK: Class Properties

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBuildTeamButton()

    }
    
    func setBuildTeamButton() {
        
        let button = CreatGroupButton()
        button.addTarget(self, action: #selector(creatGroup), for: .touchUpInside)
        view.addSubview(button)
    
    }
    
    @objc func creatGroup() {

//        performSegue(withIdentifier: SegueIdentifier.buildTeam.rawValue, sender: nil)
        if let createGroupViewController = storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController {
            let navBar = UINavigationController.init(rootViewController: createGroupViewController)
            if let sheetPresentationController = navBar.sheetPresentationController {
                sheetPresentationController.detents = [.medium(),.large()]
                self.navigationController?.present(navBar, animated: true, completion: .none)
                }
        }
    }

}
