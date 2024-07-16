//
//  CreateGroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import MJRefresh
import SwiftUI
import UIKit

protocol Reload {
    func reload()
}

class CreateGroupViewController: BaseViewController, UITextFieldDelegate {
    private var group = Group()

    var delegate: Reload?

    @IBOutlet var sendData: UIButton! {
        didSet {
            sendData.isUserInteractionEnabled = false
            sendData.alpha = 0.9
            sendData.backgroundColor = .B5
            sendData.tintColor = .B2
            sendData.cornerRadius = 15
        }
    }

    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }

    @IBOutlet var teamView: UIStackView!

    @IBOutlet var headerView: UIView!

    @IBOutlet var groupName: UITextField! {
        didSet {
            groupName.delegate = self

            groupName.setLeftPaddingPoints(8)
        }
    }

    @IBOutlet var datePicker: UIDatePicker!

    @IBOutlet var routeName: UITextField! {
        didSet {
            routeName.delegate = self

            routeName.setLeftPaddingPoints(8)
        }
    }

    @IBOutlet var limitPeople: UITextField! {
        didSet {
            limitPeople.delegate = self

            limitPeople.setLeftPaddingPoints(8)
        }
    }

    @IBOutlet var notes: UITextView!

    @IBOutlet var note: UITextField! {
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
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

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
        let textfields = [groupName, routeName, limitPeople]

        if notes.text != nil {
            textsWerefilled = textfields.allSatisfy { $0?.text?.isEmpty == false }
        }
    }

    @objc
    func sendPost() {
        guard let hostId = Auth.auth().currentUser?.uid else {
            return
        }

        textViewDidEndEditing(notes)

        group.hostId = hostId

        group.date = Timestamp(date: datePicker.date)

        group.userIds = [hostId]

        if group.date.checkIsExpired() {
            teamView.shake()

            showAlert(provider: .init(title: "揪團時間錯誤", message: "請更改日期", preferredStyle: .alert, actions: [.init(title: "取消", style: .default)]))


        } else {
            GroupManager.shared.buildTeam(group: &group) { result in

                switch result {
                case .success:

                    let sheet = UIAlertController(title: "成功揪團囉", message: NSLocalizedString("", comment: "no comment"), preferredStyle: .alert)

                    let successOption = UIAlertAction(title: "完成", style: .cancel) { _ in
                        self.delegate?.reload()
                        self.dismiss(animated: true, completion: nil)
                    }

                    sheet.addAction(successOption)
                    present(sheet, animated: true, completion: nil)

                    delegate?.reload()

                case let .failure(error):

                    print("build team failure: \(error)")

                    LKProgressHUD.show(.failure("新增資料失敗"))
                }
            }
        }
    }
}

// MARK: - TextField & TextView Delegate -

extension CreateGroupViewController: UITextViewDelegate {
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
