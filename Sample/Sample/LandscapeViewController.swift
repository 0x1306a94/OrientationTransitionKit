//
//  LandscapeViewController.swift
//  Sample
//
//  Created by KK on 2026/6/28.
//

import UIKit

class LandscapeViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscapeRight
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeRight
    }
}
