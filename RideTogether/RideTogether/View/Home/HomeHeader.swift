//
//  HomeHeader.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/1.
//

import UIKit

class HomeHeader: UITableViewHeaderFooterView {
    
    static let reuseIdentifier = "HomeHeader"
    
    // MARK: - Animation Properties
    var lengthStartValue: Double = 0.0
    var groupsStartValue: Int = 0
    var lengthEndValue: Double = 0.0
    var groupsEndValue: Int = 0
    var lengthDiff: Double = 0.0
    var groupsDiff: Int = 0
    private var displayLink: CADisplayLink?

    // MARK: - UI Components
    let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40)
        label.textColor = UIColor(named: "B5")
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let totalKmsLabel: UILabel = {
        let label = UILabel()
        label.text = "0.0"
        label.font = UIFont.systemFont(ofSize: 60)
        label.textColor = UIColor(named: "B5")
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let totalKmsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "累積公里"
        label.font = UIFont.systemFont(ofSize: 25)
        label.textColor = UIColor(named: "B5")
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let totalGroupsLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UIFont.systemFont(ofSize: 60)
        label.textColor = UIColor(named: "B5")
        label.textAlignment = .right
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let totalGroupsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "累積群組"
        label.font = UIFont.systemFont(ofSize: 25)
        label.textColor = UIColor(named: "B5")
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let leftStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .trailing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Initializer
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        contentView.backgroundColor = .clear
        backgroundView = nil

        // 1. Add Subviews
        contentView.addSubview(userNameLabel)
        
        leftStackView.addArrangedSubview(totalKmsLabel)
        leftStackView.addArrangedSubview(totalKmsTitleLabel)
        contentView.addSubview(leftStackView)

        rightStackView.addArrangedSubview(totalGroupsLabel)
        rightStackView.addArrangedSubview(totalGroupsTitleLabel)
        contentView.addSubview(rightStackView)

        // 2. Constraints
        NSLayoutConstraint.activate([
            // UserName Label Constraints
            userNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            userNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            // Left StackView Constraints (累積公里)
            leftStackView.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 25),
            leftStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            // Right StackView Constraints (累積群組)
            rightStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 114),
            rightStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),

            // Label Dimensions Matching Original XIB Constraints
            totalKmsLabel.widthAnchor.constraint(equalToConstant: 150),
            totalKmsLabel.heightAnchor.constraint(equalToConstant: 100),

            totalGroupsLabel.widthAnchor.constraint(equalToConstant: 150),
            totalGroupsLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    // MARK: - Logic & Animation
    func updateUserInfo(user: UserInfo) {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))
        displayLink?.add(to: .current, forMode: .default)

        lengthEndValue = user.totalLength / 1000
        groupsEndValue = user.totalGroups
        lengthDiff = lengthEndValue - lengthStartValue
        groupsDiff = groupsEndValue - groupsStartValue

        userNameLabel.text = user.userName
    }

    @objc private func handleUpdate() {
        let length = String(format: "%.1f", lengthStartValue)
        totalKmsLabel.text = "\(length)"
        totalGroupsLabel.text = "\(groupsStartValue)"

        lengthStartValue += 5
        groupsStartValue += 1

        if lengthStartValue >= lengthEndValue {
            lengthStartValue = lengthEndValue
        }

        if groupsStartValue >= groupsEndValue {
            groupsStartValue = groupsEndValue
        }

        if lengthStartValue == lengthEndValue && groupsStartValue == groupsEndValue {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    deinit {
        displayLink?.invalidate()
    }
}
