//
//  CreateGroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import MASegmentedControl
import MJRefresh
import RSKPlaceholderTextView
import SwiftUI
import UIKit

protocol Reload {
    func reload()
}

class CreateGroupViewController: BaseViewController {
    
    // MARK: - Properties -
    
    private var group = Group()
    var delegate: Reload?

    private var textsWerefilled: Bool = false {
        didSet {
            sendData.isUserInteractionEnabled = textsWerefilled
            sendData.alpha = textsWerefilled ? 1.0 : 0.5
        }
    }

    // MARK: - UI Components -

    private lazy var gView: UIView = {
        let view = UIView()
        view.applyGradient(
            colors: [.white, .B3],
            locations: [0.0, 1.0], direction: .leftSkewed
        )
        view.alpha = 0.85
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "建立活動"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = UIColor(named: "B5")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "groups")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.alpha = 0.8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: Form UI Components

    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.text = "團名"
        label.textColor = UIColor(named: "B5")
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var groupName: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14)
        tf.delegate = self
        tf.setLeftPaddingPoints(8)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.text = "日期"
        label.textColor = UIColor(named: "B5")
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "zh")
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private lazy var routeNameLabel: UILabel = {
        let label = UILabel()
        label.text = "路線"
        label.textColor = UIColor(named: "B5")
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var routeName: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14)
        tf.delegate = self
        tf.setLeftPaddingPoints(8)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var limitPeopleLabel: UILabel = {
        let label = UILabel()
        label.text = "人數"
        label.textColor = UIColor(named: "B5")
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var limitPeople: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14)
        tf.delegate = self
        tf.setLeftPaddingPoints(8)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var notesLabel: UILabel = {
        let label = UILabel()
        label.text = "備註"
        label.textColor = UIColor(named: "B5")
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var note: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14)
        tf.placeholder = "有哪些需要注意的事項？"
        tf.delegate = self
        tf.layer.cornerRadius = 10
        tf.clipsToBounds = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // 備註使用的相容別名 (原先代碼中的 notes 指向 note)
    private var notes: UITextField { note }

    // 主表單 StackView
    private lazy var teamView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var sendData: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("騎車愛地球", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        button.backgroundColor = .B5
        button.tintColor = .B2
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUI()
        setUpButton()
    }

    // MARK: - UI Setup -

    private func setUpUI() {
        view.backgroundColor = .systemBackground

        // 1. 新增背景 View
        view.addSubview(gView)

        // 2. 新增主要控制元件
        view.addSubview(titleLabel)
        view.addSubview(coverImageView)
        view.addSubview(teamView)
        view.addSubview(sendData)

        // 3. 組裝 Form 各行 StackView
        let groupNameStack = createHorizontalStack(label: groupNameLabel, input: groupName, labelWidth: 60)
        let dateStack = createHorizontalStack(label: dateLabel, input: datePicker, labelWidth: nil)
        let routeStack = createHorizontalStack(label: routeNameLabel, input: routeName, labelWidth: 60)
        let limitStack = createHorizontalStack(label: limitPeopleLabel, input: limitPeople, labelWidth: 60)

        let notesStack = UIStackView(arrangedSubviews: [notesLabel, note])
        notesStack.axis = .vertical
        notesStack.spacing = 8
        notesStack.alignment = .leading

        teamView.addArrangedSubview(groupNameStack)
        teamView.addArrangedSubview(dateStack)
        teamView.addArrangedSubview(routeStack)
        teamView.addArrangedSubview(limitStack)
        teamView.addArrangedSubview(notesStack)

        // 4. 設定所有 Constraints
        setupConstraints()
    }

    private func createHorizontalStack(label: UIView, input: UIView, labelWidth: CGFloat?) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [label, input])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill

        if let width = labelWidth {
            stack.spacing = 23
            NSLayoutConstraint.activate([
                label.widthAnchor.constraint(equalToConstant: width)
            ])
        } else {
            stack.spacing = 7
        }

        return stack
    }

    private func setupConstraints() {
        let margin: CGFloat = 47.5

        NSLayoutConstraint.activate([
            // Background View Constraints
            gView.topAnchor.constraint(equalTo: view.topAnchor),
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -5),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),

            // Cover Image View
            coverImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            coverImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            coverImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),
            coverImageView.heightAnchor.constraint(equalToConstant: 140),

            // Form Stack View (teamView)
            teamView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 20),
            teamView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            teamView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),

            // Input Heights
            groupNameLabel.heightAnchor.constraint(equalToConstant: 30),
            groupName.heightAnchor.constraint(equalToConstant: 30),
            dateLabel.heightAnchor.constraint(equalToConstant: 30),
            datePicker.heightAnchor.constraint(equalToConstant: 30),
            datePicker.widthAnchor.constraint(equalToConstant: 220),
            routeNameLabel.heightAnchor.constraint(equalToConstant: 30),
            routeName.heightAnchor.constraint(equalToConstant: 30),
            limitPeopleLabel.heightAnchor.constraint(equalToConstant: 30),
            limitPeople.heightAnchor.constraint(equalToConstant: 30),
            notesLabel.heightAnchor.constraint(equalToConstant: 30),
            note.heightAnchor.constraint(equalToConstant: 60),
            note.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),

            // Send Button
            sendData.topAnchor.constraint(equalTo: teamView.bottomAnchor, constant: 12),
            sendData.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            sendData.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),
            sendData.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setUpButton() {
        sendData.addTarget(self, action: #selector(sendPost), for: .touchUpInside)
    }

    // MARK: - Check Texts Filled -

    func checkTextsFilled() {
        let textfields = [groupName, routeName, limitPeople]

        if notes.text != nil {
            textsWerefilled = textfields.allSatisfy { $0.text?.isEmpty == false }
        }
    }

    @objc func sendPost() {
        guard let hostId = Auth.auth().currentUser?.uid else { return }

        group.hostId = hostId
        group.date = Timestamp(date: datePicker.date)
        group.userIds = [hostId]

        if group.date.checkIsExpired() {
            teamView.shake()
            showAlertAction(title: "揪團時間錯誤", message: "請更改日期")
        } else {
            GroupManager.shared.buildTeam(group: &group) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    let sheet = UIAlertController(title: "成功揪團囉", message: "", preferredStyle: .alert)
                    let successOption = UIAlertAction(title: "完成", style: .cancel) { _ in
                        self.delegate?.reload()
                        self.dismiss(animated: true, completion: nil)
                    }
                    sheet.addAction(successOption)
                    self.present(sheet, animated: true, completion: nil)

                case let .failure(error):
                    print("build team failure: \(error)")
                    LKProgressHUD.showFailure(text: "新增資料失敗")
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate & UITextViewDelegate -

extension CreateGroupViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        var maxLength = 12
        if textField == limitPeople {
            maxLength = 2
        }

        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString

        return newString.length <= maxLength
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }

        switch textField {
        case groupName:
            group.groupName = text
        case routeName:
            group.routeName = text
        case limitPeople:
            group.limit = Int(text) ?? 1
        case note:
            group.note = text
        default:
            return
        }

        checkTextsFilled()
    }
}
