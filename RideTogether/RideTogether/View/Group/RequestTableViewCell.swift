//
//  RequestTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import UIKit
import FirebaseFirestore
import RSKPlaceholderTextView

class RequestTableViewCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {

    var groupInfo: Group?
    
    
    @IBOutlet weak var hostButton: UIButton!
    
    @IBOutlet weak var trailName: UITextField! {
        didSet {
            trailName.delegate = self
        }
    }
    
    
    @IBOutlet weak var numberOfPeople: UITextField! {
        didSet {
            numberOfPeople.delegate = self
        }
    }
    
    
    @IBOutlet weak var note: UITextView! {
        didSet {
            note.isScrollEnabled = false
            note.delegate = self
        }
    }
    
    @IBOutlet weak var travelDate: UILabel!
    
    @IBOutlet weak var travelTime: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var travelTimePicker: UIDatePicker!
    
    @IBOutlet weak var hostName: UILabel!
    
    
    @IBOutlet weak var gButton: UIButton!
    
    
    var isEditting: Bool = false {
        
        didSet {
            trailName.isEnabled = isEditting ? true : false
            
            trailName.textColor = isEditting ? .black : .B1
            
            trailName.backgroundColor = isEditting ? .systemPink : .clear
            
            numberOfPeople.isEnabled = isEditting ? true : false
            
            numberOfPeople.textColor = isEditting ? .black : .B1
            
            numberOfPeople.backgroundColor = isEditting ? .systemPink : .clear
            
            note.isEditable = isEditting ? true : false
            
            note.textColor = isEditting ? .black : .B1
            
            note.backgroundColor = isEditting ? .systemPink : .clear
            
            travelDate.isHidden = isEditting ? true : false
            
            travelTime.isHidden = isEditting ? true : false
            
            timeLabel.isHidden = isEditting ? true : false
            
            travelTimePicker.isHidden = isEditting ? false : true
            
            travelTimePicker.backgroundColor = isEditting ? UIColor.systemPink : .clear
            
            
            if isEditting {
                
                numberOfPeople.text = groupInfo?.limit.description
                travelTimePicker.date = groupInfo?.date.dateValue() ?? Date()
                
            } else {
                let pickTime = Timestamp(date: travelTimePicker.date)
                groupInfo?.date = pickTime
                
                guard let groupInfo = groupInfo else {
                    return
                }
                travelDate.text = TimeFormater.dateStyle.timestampToString(time: groupInfo.date)
                
                travelTime.text = TimeFormater.timeStyle.timestampToString(time: groupInfo.date)
                
                note.text = groupInfo.note
                
                let upperlimit = groupInfo.limit
                
                let counts = groupInfo.userIds.count
                
                numberOfPeople.text = "\(counts) / \(upperlimit)"
            }
        }
    }
    
    func setUpCell(group: Group, cashe: UserInfo, userStatus: GroupStatus) {
        
        self.groupInfo = group
        
        guard let groupInfo = groupInfo else {
            return
        }
        
        travelDate.text = TimeFormater.dateStyle.timestampToString(time: groupInfo.date)
        
        travelTime.text = TimeFormater.timeStyle.timestampToString(time: groupInfo.date)
        
    }
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
   
    
}
