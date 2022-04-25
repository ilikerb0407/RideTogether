//
//  RequestTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import UIKit
import FirebaseFirestore
import RSKPlaceholderTextView

class RequestTableViewCell: UITableViewCell, UITextFieldDelegate {

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
    
    
    
    
    @IBOutlet weak var gButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpCell(model: Request) {
        
        
    }
    
}
