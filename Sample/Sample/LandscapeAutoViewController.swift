//
//  LandscapeAutoViewController.swift
//  Sample
//
//  Created by KK on 2026/6/28.
//

import UIKit

class LandscapeAutoViewController: BaseViewController {
    let playerContainerView = UIView()
    private let closeButton = UIButton(type: .custom)
    private let userInfoButton = UIButton(type: .custom)

    var didTapUserInfoHandler: ((LandscapeAutoViewController) -> Void)?
    let transitionSourceAnchorView = UIView()

    let sourceContainerView: UIView
    let sourceFrame: CGRect
    let transitionContentView: UIView
    var transitionLayoutConstraints: [NSLayoutConstraint] = []

    private var shouldHideHomeIndicator = false

    private var landscape = false

    init(sourceContainerView: UIView, transitionContentView: UIView) {
        self.sourceContainerView = sourceContainerView
        self.sourceFrame = sourceContainerView.window!.convert(transitionContentView.bounds, from: transitionContentView)
        self.transitionContentView = transitionContentView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        transitionSourceAnchorView.backgroundColor = .clear
        transitionSourceAnchorView.translatesAutoresizingMaskIntoConstraints = false

        playerContainerView.backgroundColor = .black
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false

        transitionContentView.translatesAutoresizingMaskIntoConstraints = false

        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.55)
        closeButton.layer.cornerRadius = 6
        closeButton.clipsToBounds = true
        closeButton.setTitle("退出全屏", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        userInfoButton.backgroundColor = UIColor(white: 0, alpha: 0.55)
        userInfoButton.layer.cornerRadius = 6
        userInfoButton.clipsToBounds = true
        userInfoButton.setTitle("用户主页", for: .normal)
        userInfoButton.setTitleColor(.white, for: .normal)
        userInfoButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        userInfoButton.translatesAutoresizingMaskIntoConstraints = false
        userInfoButton.addTarget(self, action: #selector(userInfoButtonTapped), for: .touchUpInside)

        view.addSubview(transitionSourceAnchorView)
        view.addSubview(playerContainerView)
        playerContainerView.addSubview(transitionContentView)
        view.addSubview(closeButton)
        view.addSubview(userInfoButton)

        transitionLayoutConstraints = [
            playerContainerView.widthAnchor.constraint(equalTo: transitionSourceAnchorView.widthAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: transitionSourceAnchorView.heightAnchor),
            playerContainerView.centerXAnchor.constraint(equalTo: transitionSourceAnchorView.centerXAnchor),
            playerContainerView.centerYAnchor.constraint(equalTo: transitionSourceAnchorView.centerYAnchor),
        ]

        NSLayoutConstraint.activate(
            transitionLayoutConstraints +
                [
                    transitionSourceAnchorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sourceFrame.minX),
                    transitionSourceAnchorView.topAnchor.constraint(equalTo: view.topAnchor, constant: sourceFrame.minY),
                    transitionSourceAnchorView.widthAnchor.constraint(equalToConstant: sourceFrame.width),
                    transitionSourceAnchorView.heightAnchor.constraint(equalToConstant: sourceFrame.height),

                    transitionContentView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
                    transitionContentView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
                    transitionContentView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
                    transitionContentView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),

                    closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                    closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    closeButton.widthAnchor.constraint(equalToConstant: 96),
                    closeButton.heightAnchor.constraint(equalToConstant: 44),

                    userInfoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                    userInfoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    userInfoButton.widthAnchor.constraint(equalToConstant: 96),
                    userInfoButton.heightAnchor.constraint(equalToConstant: 44),
                ]
        )
    }

    override var shouldAutorotate: Bool {
        false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        landscape ? .landscapeRight : .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        shouldHideHomeIndicator
    }

    @objc private func closeButtonTapped() {
//        dismiss(animated: true)
        landscape.toggle()
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            // Fallback on earlier versions
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    @objc private func userInfoButtonTapped() {
        didTapUserInfoHandler?(self)
    }

    private func setHomeIndicatorHidden(_ isHidden: Bool) {
        shouldHideHomeIndicator = isHidden
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print(#function)
        NSLayoutConstraint.deactivate(transitionLayoutConstraints)

        if landscape {
            transitionLayoutConstraints = [
                playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
                playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        } else {
            transitionLayoutConstraints = [
                playerContainerView.widthAnchor.constraint(equalTo: transitionSourceAnchorView.widthAnchor),
                playerContainerView.heightAnchor.constraint(equalTo: transitionSourceAnchorView.heightAnchor),
                playerContainerView.centerXAnchor.constraint(equalTo: transitionSourceAnchorView.centerXAnchor),
                playerContainerView.centerYAnchor.constraint(equalTo: transitionSourceAnchorView.centerYAnchor),
            ]
        }

        NSLayoutConstraint.activate(transitionLayoutConstraints)
        view.setNeedsLayout()
        coordinator.animate { [weak self] _ in
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            print(self?.view.window?.windowScene?.interfaceOrientation.rawValue)
        }
    }
}
