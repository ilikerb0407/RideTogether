//
//  RequestTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import FirebaseFirestore
import UIKit

class RequestTableViewCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {
    var groupInfo: Group?

    @IBOutlet var hostButton: UIButton!

    @IBOutlet var trailName: UITextField! {
        didSet {
            trailName.delegate = self
        }
    }

    @IBOutlet var numberOfPeople: UITextField! {
        didSet {
            numberOfPeople.delegate = self
        }
    }

    @IBOutlet var note: UITextView! {
        didSet {
            note.isScrollEnabled = false
            note.delegate = self
        }
    }

    @IBOutlet var travelDate: UILabel!

    @IBOutlet var travelTime: UILabel!

    @IBOutlet var timeLabel: UILabel!

    @IBOutlet var travelTimePicker: UIDatePicker!

    @IBOutlet var hostName: UILabel!

    @IBOutlet var gButton: UIButton!

    var isEditting: Bool = false {
        didSet {
            trailName.isEnabled = isEditting ? true : false

            trailName.textColor = isEditting ? .black : .B5

            trailName.backgroundColor = isEditting ? .white : .clear

            numberOfPeople.isEnabled = isEditting ? true : false

            numberOfPeople.textColor = isEditting ? .black : .B5

            numberOfPeople.backgroundColor = isEditting ? .white : .clear

            note.isEditable = isEditting ? true : false

            note.textColor = isEditting ? .black : .B5

            note.backgroundColor = isEditting ? .white : .white

            travelDate.isHidden = isEditting ? true : false

            travelTime.isHidden = isEditting ? true : false

            timeLabel.isHidden = isEditting ? true : false

            travelTimePicker.isHidden = isEditting ? false : true

            travelTimePicker.backgroundColor = isEditting ? .clear : .clear

            travelTimePicker.cornerRadius = 20

            if isEditting {
                numberOfPeople.text = groupInfo?.limit.description

                travelTimePicker.date = groupInfo?.date.dateValue() ?? Date()

            } else {
                let pickTime = Timestamp(date: travelTimePicker.date)
                groupInfo?.date = pickTime

                guard let groupInfo else {
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

    func setUpCell(group: Group, cache: UserInfo, userStatus: GroupStatus) {
        self.groupInfo = group

        guard let groupInfo else {
            return
        }

        travelDate.text = TimeFormater.dateStyle.timestampToString(time: groupInfo.date)

        travelTime.text = TimeFormater.timeStyle.timestampToString(time: groupInfo.date)

        trailName.text = group.routeName

        let upperlimit = group.limit

        let counts = group.userIds.count

        numberOfPeople.text = "\(counts)/\(upperlimit)"

        hostName.text = cache.userName

        note.text = group.note

        if group.isExpired == true {
            gButton.isHidden = true
        }

        switch userStatus {
        case .ishost:

            hostButton.isHidden = false

            gButton.setTitle("編輯資訊", for: .normal)

        case .notInGroup:

            gButton.setTitle("送出申請", for: .normal)

            guard counts != upperlimit else {
                gButton.setTitle("已經額滿", for: .normal)

                gButton.isEnabled = false

                return
            }

        case .isInGroup:

            gButton.setTitle("退出隊伍", for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        self.backgroundColor = .clear

        gButton.titleLabel?.font = UIFont.regular(size: 20)

        setUpTextView()

        setUpTextField()

        trailName.isEnabled = false

        numberOfPeople.isEnabled = false

        note.isEditable = false

        travelDate.isHidden = false

        travelTime.isHidden = false

        timeLabel.isHidden = false
//      =====
        travelTimePicker.isHidden = true

        hostButton.isHidden = true
    }

    func setUpTextView() {
        note.backgroundColor = .white

        note.textAlignment = .left

        note.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        note.font = UIFont.systemFont(ofSize: 15, weight: .light)

        note.clipsToBounds = true

        note.layer.cornerRadius = 10

        note.textContainer.maximumNumberOfLines = 3

        note.textContainer.lineBreakMode = .byWordWrapping
    }

    func setUpTextField() {
        trailName.setLeftPaddingPoints(8)

        trailName.layer.cornerRadius = 10

        trailName.font = UIFont.systemFont(ofSize: 15, weight: .light)

        trailName.clipsToBounds = true

        travelDate.font = UIFont.systemFont(ofSize: 15, weight: .light)

        travelTime.font = UIFont.systemFont(ofSize: 15, weight: .light)

        numberOfPeople.setLeftPaddingPoints(8)

        numberOfPeople.layer.cornerRadius = 10

        numberOfPeople.font = UIFont.systemFont(ofSize: 15, weight: .light)

        numberOfPeople.clipsToBounds = true

        hostName.font = UIFont.systemFont(ofSize: 15, weight: .light)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let text = textView.text,
              !text.isEmpty else {
            return
        }

        note.text = text

        groupInfo?.note = text
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text,
              !text.isEmpty else {
            return
        }

        switch textField {
        case trailName:

            trailName.text = text

            groupInfo?.routeName = text

        case numberOfPeople:

            numberOfPeople.text = text

            groupInfo?.limit = Int(text) ?? 1

        default:

            return
        }
    }
}
