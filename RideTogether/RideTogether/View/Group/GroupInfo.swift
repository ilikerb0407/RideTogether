//
//  GroupInfo.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/21.
//

import UIKit

class GroupInfo: UITableViewCell {

    @IBOutlet weak var hostMarker: UIImageView!
    
    @IBOutlet weak var cellView: UIView!
    
    @IBOutlet weak var groupName: UILabel!
    
    @IBOutlet weak var routeName: UILabel!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var limitPeople: UILabel!
    
    @IBOutlet weak var time: UILabel!
    
    @IBOutlet weak var hostName: UILabel!
    
    @IBOutlet weak var isOver: UILabel!
    
//    (group: Group, hostname: String)
    func setUpCell(group: Group, hostname: String) {
        
        groupName.text = group.groupName
        routeName.text = group.routeName
        date.text = TimeFormater.dateStyle.timestampToString(time: group.date)
        
        time.text = TimeFormater.timeStyle.timestampToString(time: group.date)
        hostName.text = hostname
        
        let limit = group.limit.description
        let count = group.userIds.count
        limitPeople.text = "\(count)/\(limit)"
        
        
        let userInfo = UserManager.shared.userInfo
        
        if group.hostId == userInfo.uid {
            hostMarker.isHidden = false
        } else {
            hostMarker.isHidden = true
        }
        
        
        if group.isExpired == true {
            
            isOver.isHidden = false
            isOver.backgroundColor = .systemGray4
            
        } else {
            
            isOver.isHidden = true
            isOver.backgroundColor = .white

        }

    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        selectionStyle = .none
        self.backgroundColor = .clear
        
    }
    
}
