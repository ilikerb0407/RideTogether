//
//  GroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit

class GroupViewController: BaseViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBuildTeamButton()

    }
    
    func setBuildTeamButton() {
        
        let button = CreatGroupButton()
        let width = UIScreen.width
        let height = UIScreen.height
        button.frame = CGRect(x: width * 0.8, y: height * 0.8, width: 70, height: 70)
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
