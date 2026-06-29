//
//  LandscapeViewController.swift
//  Sample
//
//  Created by KK on 2026/6/28.
//

import OrientationTransitionKit
import UIKit

class LandscapeViewController: BaseViewController {
    let playerContainerView = UIView()
    private let closeButton = UIButton(type: .custom)
    private let userInfoButton = UIButton(type: .custom)

    var didTapUserInfoHandler: ((LandscapeViewController) -> Void)?
    weak var transitionContentView: UIView?
    private var shouldHideHomeIndicator = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        playerContainerView.backgroundColor = .black
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false

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

        view.addSubview(playerContainerView)
        view.addSubview(closeButton)
        view.addSubview(userInfoButton)

        NSLayoutConstraint.activate([
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: view.heightAnchor),

            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 96),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            userInfoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            userInfoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            userInfoButton.widthAnchor.constraint(equalToConstant: 96),
            userInfoButton.heightAnchor.constraint(equalToConstant: 44),
        ])
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

    override var prefersHomeIndicatorAutoHidden: Bool {
        shouldHideHomeIndicator
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func userInfoButtonTapped() {
        didTapUserInfoHandler?(self)
    }

    private func setHomeIndicatorHidden(_ isHidden: Bool) {
        shouldHideHomeIndicator = isHidden
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
}

extension LandscapeViewController: TransitionToContextProvider {
    func transitionToContextProviderViewController(_ contextProvider: TransitionToContextProvider) -> UIViewController {
        self
    }

    func transitionToContextProviderTransitionFrame(_ contextProvider: TransitionToContextProvider, in containerView: UIView) -> CGRect {
        containerView.convert(playerContainerView.bounds, from: playerContainerView)
    }

    func transitionToContextProviderPrepareTransitionView(_ contextProvider: TransitionToContextProvider, transitionView: UIView) {
        moveTransitionContent(to: transitionView)
    }

    func transitionToContextProviderFinishTransitionView(_ contextProvider: TransitionToContextProvider) {
        moveTransitionContent(to: playerContainerView)
    }

    func transitionToContextProviderTransitionWillEnter(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider) {
        setHomeIndicatorHidden(true)
    }

    func transitionToContextProviderTransitionDidEnter(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider) {
        setHomeIndicatorHidden(true)
    }

    func transitionToContextProviderTransitionWillExit(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider) {
        setHomeIndicatorHidden(true)
    }

    func transitionToContextProviderTransitionDidExit(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider) {
        setHomeIndicatorHidden(false)
    }

    private func moveTransitionContent(to containerView: UIView) {
        guard let transitionContentView else {
            return
        }

        transitionContentView.removeFromSuperview()
        transitionContentView.transform = .identity
        transitionContentView.frame = containerView.bounds
        transitionContentView.translatesAutoresizingMaskIntoConstraints = false
//        transitionContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(transitionContentView)
        NSLayoutConstraint.activate([
            transitionContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            transitionContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            transitionContentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            transitionContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }
}
