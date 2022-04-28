//
//  CreateGroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit
import Firebase
import MJRefresh
import MASegmentedControl
import FirebaseAuth
import FirebaseFirestore
import RSKPlaceholderTextView
import SwiftUI

protocol Reload {
    
    func reload()
    
}

class CreateGroupViewController: BaseViewController, UITextFieldDelegate {
    
    private var group = Group()
    
    var delegate: Reload?
    
    
    @IBOutlet weak var sendData: UIButton! {
        didSet{
            sendData.isUserInteractionEnabled = false
            sendData.alpha = 0.6
            sendData.backgroundColor = .orange
            sendData.cornerRadius = 24
        }
    }
    
    @IBOutlet weak var teamView: UIStackView!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var groupName: UITextField! {
        didSet {
            
            groupName.delegate = self
            
            groupName.setLeftPaddingPoints(8)
        }
    }
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var routeName: UITextField! {
        didSet {
            
            routeName.delegate = self
            
            routeName.setLeftPaddingPoints(8)
        }
    }
    
    @IBOutlet weak var limitPeople: UITextField! {
        didSet {
            
            limitPeople.delegate = self
            
            limitPeople.setLeftPaddingPoints(8)
        }
    }
    @IBOutlet weak var notes: UITextView!
    
    @IBOutlet weak var note: UITextField! {
        didSet {
            
            note.delegate = self
        }
    }
    
    private var textsWerefilled: Bool = false {
        
        didSet {
            
            sendData.isUserInteractionEnabled = textsWerefilled
            
            sendData.alpha = textsWerefilled ? 1.0 : 0.5
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpButton()
        
        view.backgroundColor = .B2
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
//        headerView.applyGradient(colors: [.C4, .B2], locations: [0.0, 1.0], direction: .topToBottom)
//
//        headerView.roundCornersTop(cornerRadius: 15)
        
        setUpTextView()
        
    }
    
    // MARK: - UI Settings -
    
    func setUpTextView() {
        
        note.placeholder = "有哪些需要注意的事項？"
        
        note.clipsToBounds = true
        
        note.layer.cornerRadius = 10
        
    }
    
    func setUpButton() {
        
        sendData.addTarget(self, action: #selector(sendPost), for: .touchUpInside)
    }
    
    // MARK: check text Field
    
    func checkTextsFilled() {
        
        let textfields = [ groupName, routeName, limitPeople]
        
        if notes.text != nil {
            
            textsWerefilled = textfields.allSatisfy { $0?.text?.isEmpty  == false }
        }
    }
    
    @objc func sendPost() {
        
        guard let hostId = Auth.auth().currentUser?.uid else { return }
        
        textViewDidEndEditing(notes)
        
        group.hostId = hostId
        
        group.date = Timestamp(date: datePicker.date)
        
        group.userIds = [hostId]
        
        if group.date.checkIsExpired() {
            
            teamView.shake()
            
            showAlertAction(title: "揪團時間錯誤", message: "請更改日期")
            
        } else {
            
            GroupManager.shared.buildTeam(group: &group) { result in
                
                switch result {
                    
                case .success:
                    

                    let success = UIAlertAction(title: "Success", style: .default) { _ in
                        self.delegate?.reload()
                    }
                    
                    self.dismiss(animated: true, completion: nil)
                    
                    showAlertAction(title: "開啟揪團囉", message: nil, actions: [success])
                    
                case .failure(let error):
                    
                    print("build team failure: \(error)")
                }
            }
        }
    }
    
}

// MARK: - TextField & TextView Delegate -

 extension CreateGroupViewController :  UITextViewDelegate {
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        var maxLength = 12
        
        if textField == limitPeople {
            maxLength = 2
        }
        
        let currentString: NSString = (textField.text ?? "") as NSString
        
        let newString: NSString =
        currentString.replacingCharacters(in: range, with: string) as NSString
        
        return newString.length <= maxLength
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        guard let text = textView.text,
              !text.isEmpty else {
                  return
              }
        
        group.note = text
        checkTextsFilled()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard let text = textField.text, !text.isEmpty else {
            return
        }
        
        switch textField {
            
        case groupName:
            
            group.groupName = text
            
        case routeName:
            
            group.routeName = text
            
        case limitPeople:
            
            group.limit = Int(text) ?? 1
            
        default:
            
            return
        }
        
        checkTextsFilled()
    }
}






