//
//  UserInfoViewController.swift
//  OrientationTransitionKitSample
//
//  Created by KK on 2026/6/28.
//

import UIKit

class UserInfoViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green

        let testLabel = UILabel()
        testLabel.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        testLabel.text = "Test"
        self.view.addSubview(testLabel)
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        testLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        testLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
}
