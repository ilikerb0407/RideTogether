//
//  RequestTableViewCell.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//
//  This used to be loaded from RequestTableViewCell.xib. Rebuilt in code
//  here — layout matches the XIB, with two intentional differences noted
//  where the original had genuine issues (not stylistic choices):
//
//  1. The "團長 / hostName" stack (`teamLeaderStackView` below) had THREE
//     separate top constraints in the XIB, each pinned to a different
//     sibling. They happened to all resolve to the same position (128.5pt
//     from the top) given the other views' geometry, so nothing was
//     visually broken — but it's redundant, accumulated debt from
//     repeatedly repositioning the view in Interface Builder. Only one
//     equivalent constraint is kept here.
//  2. The "時間" label (`timeLabel` below) had no vertical (top) position
//     constraint at all in the XIB — only a horizontal spacing constraint
//     to its neighbor. That's a genuinely incomplete/ambiguous layout.
//     Given an explicit centerY alignment with `travelDate` here, since
//     they visually belong to the same display row.
//
//  Everything else (fonts, corner radii, colors, spacing, the `isEditting`
//  state logic, `setUpCell`, text field/view delegate handling) is
//  unchanged from the original.
//
//  Note on `awakeFromNib()`: since this cell is no longer loaded from a
//  nib, that method is never called anymore. Its setup logic has moved
//  into `init(style:reuseIdentifier:)` below.

import FirebaseFirestore
import RSKPlaceholderTextView
import UIKit

class RequestTableViewCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {
    var groupInfo: Group?

    // MARK: - Views migrated from RequestTableViewCell.xib

    let hostButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "發起人"
        configuration.baseBackgroundColor = .B5
        let button = UIButton(configuration: configuration)
        button.backgroundColor = .B2
        button.tintColor = .B5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let trailName: UITextField = {
        let textField = UITextField()
        textField.text = "悠閒的路線"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.layer.cornerRadius = 15
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    let numberOfPeople: UITextField = {
        let textField = UITextField()
        textField.text = "10"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14)
        textField.layer.cornerRadius = 15
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    let note: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.textAlignment = .justified
        textView.font = .systemFont(ofSize: 19)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    let travelDate: UILabel = {
        let label = UILabel()
        label.text = "日期"
        label.font = .systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let travelTime: UILabel = {
        let label = UILabel()
        label.text = "Label"
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "時間"
        label.font = .systemFont(ofSize: 20)
        label.tintColor = .systemPink
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let travelTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.minuteInterval = 30
        picker.preferredDatePickerStyle = .compact
        picker.backgroundColor = .U1
        picker.layer.cornerRadius = 15
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    let hostName: UILabel = {
        let label = UILabel()
        label.text = "阿富"
        label.font = .systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let gButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Button"
        let button = UIButton(configuration: configuration)
        button.backgroundColor = .B5
        button.tintColor = .B2
        button.alpha = 0.9
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 15
        button.layer.borderColor = UIColor.black.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // Static (non-outlet) labels

    private let routeLabel: UILabel = {
        let label = UILabel()
        label.text = "路線"
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    private let pickerRowDateLabel: UILabel = {
        let label = UILabel()
        label.text = "日期"
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    private let numberOfPeopleLabel: UILabel = {
        let label = UILabel()
        label.text = "人數"
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    private let noteLabel: UILabel = {
        let label = UILabel()
        label.text = "備註"
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    private let hostLabel: UILabel = {
        let label = UILabel()
        label.text = "團長"
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    // Stack views grouping the rows above, matching the XIB's structure

    private lazy var routeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [routeLabel, trailName])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var dateStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [pickerRowDateLabel, travelTimePicker])
        stack.axis = .horizontal
        stack.spacing = 100
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var numberOfPeopleStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [numberOfPeopleLabel, numberOfPeople])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var teamLeaderStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [hostLabel, hostName])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        setUpCellAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
        setUpCellAppearance()
    }

    private func setUpViews() {
        [routeStackView, hostButton, dateStackView, numberOfPeopleStackView,
         noteLabel, note, gButton, teamLeaderStackView, travelDate, travelTime, timeLabel]
            .forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            routeStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            routeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            hostButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            hostButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -29),

            dateStackView.topAnchor.constraint(equalTo: routeStackView.bottomAnchor, constant: 8),
            dateStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            dateStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: -9),

            numberOfPeopleStackView.topAnchor.constraint(equalTo: dateStackView.bottomAnchor, constant: 8),
            numberOfPeopleStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),

            // "顯示用" 日期/時間 Label 這組，跟 dateStackView（編輯用的
            // travelTimePicker）刻意落在同一個垂直區域——isEditting 切換時
            // 兩組是互斥顯示的，不是排版錯誤。
            travelDate.topAnchor.constraint(equalTo: routeStackView.bottomAnchor, constant: 21),
            travelDate.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 55),

            // XIB 裡 timeLabel 本身沒有獨立的垂直定位約束（見檔案開頭
            // 註解），這裡明確補上跟 travelDate 同一水平線；水平位置則是
            // 忠實還原原本 XIB 真正存在的約束：travelTime.leading =
            // timeLabel.trailing + 11。
            timeLabel.centerYAnchor.constraint(equalTo: travelDate.centerYAnchor),

            travelTime.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 11),
            travelTime.topAnchor.constraint(equalTo: hostButton.bottomAnchor, constant: 23.5),
            travelTime.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: -36),
            travelTime.widthAnchor.constraint(equalToConstant: 66),
            travelTime.heightAnchor.constraint(equalToConstant: 20.5),

            // Was three redundant (but mutually consistent) top
            // constraints in the XIB — see header comment. Kept as one,
            // anchored to dateStackView like the other rows below it.
            teamLeaderStackView.topAnchor.constraint(equalTo: dateStackView.bottomAnchor, constant: 13),
            teamLeaderStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: -55),

            noteLabel.topAnchor.constraint(equalTo: numberOfPeopleStackView.bottomAnchor, constant: 15),
            noteLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),

            note.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 10),
            note.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            note.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: -36),
            note.heightAnchor.constraint(equalToConstant: 55),

            gButton.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 5),
            gButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -29),
            gButton.heightAnchor.constraint(equalToConstant: 31),
        ])
    }

    // Was `awakeFromNib()`. That method is only ever called when a cell
    // is actually loaded from a nib/storyboard — a cell built entirely in
    // code (as this one now is) never fires it, so all of this moved into
    // `init` instead.
    private func setUpCellAppearance() {
        selectionStyle = .none

        backgroundColor = .clear

        gButton.titleLabel?.font = UIFont.regular(size: 20)

        trailName.delegate = self
        numberOfPeople.delegate = self
        note.isScrollEnabled = false
        note.delegate = self

        setUpTextView()

        setUpTextField()

        trailName.isEnabled = false

        numberOfPeople.isEnabled = false

        note.isEditable = false

        travelDate.isHidden = false

        travelTime.isHidden = false

        timeLabel.isHidden = false

        travelTimePicker.isHidden = true

        hostButton.isHidden = true
    }

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

                guard let groupInfo = groupInfo else { return }

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

        guard let groupInfo = groupInfo else {
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
              !text.isEmpty else { return }

        note.text = text

        groupInfo?.note = text
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text,
              !text.isEmpty else { return }

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
