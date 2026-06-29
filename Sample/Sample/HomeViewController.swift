//
//  HomeViewController.swift
//  OrientationTransitionKitSample
//
//  Created by KK on 2026/6/28.
//

import OrientationTransitionKit
import UIKit

class HomeViewController: BaseViewController {
    private let playerContainerView = UIView()
    private let playerView = UIImageView()
    private let buttonStackView = UIStackView()
    private let landscapeButton = UIButton(configuration: .plain())
    private let systemRotationLandscapeButton = UIButton(configuration: .plain())
    private let positionButton = UIButton(configuration: .plain())

    private var playerContainerViewTopLayoutConstraint: NSLayoutConstraint!
    private var playerContainerViewCenterLayoutConstraint: NSLayoutConstraint!

    private var orientationTransitionCoordinator: TransitionCoordinator?
    private var systemRotationTransitionCoordinator: SystemRotationTransitionCoordinator?
    private var landscapeViewController: LandscapeViewController?
    private var pendingExitFullscreenTask: (() -> Void)?
    private var shouldHideHomeIndicator = false

    override func viewDidLoad() {
        super.viewDidLoad()

        playerContainerView.backgroundColor = .black
        playerContainerView.clipsToBounds = true
        playerContainerView.layer.cornerRadius = 20
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false

        playerView.backgroundColor = .orange
//        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.translatesAutoresizingMaskIntoConstraints = false

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20

        var positionButtonConfiguration = UIButton.Configuration.filled()
        positionButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        positionButtonConfiguration.cornerStyle = .capsule
        positionButtonConfiguration.attributedTitle = AttributedString(
            "顶部",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            ])
        )
        positionButton.configuration = positionButtonConfiguration
        positionButton.addTarget(self, action: #selector(positionButtonTapped(_:)), for: .touchUpInside)

        var landscapeButtonConfiguration = UIButton.Configuration.filled()
        landscapeButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        landscapeButtonConfiguration.cornerStyle = .capsule
        landscapeButtonConfiguration.attributedTitle = AttributedString(
            "全屏",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            ])
        )
        landscapeButton.configuration = landscapeButtonConfiguration
        landscapeButton.translatesAutoresizingMaskIntoConstraints = false
        landscapeButton.addTarget(self, action: #selector(landscapeButtonTapped), for: .touchUpInside)

        var systemRotationLandscapeButtonConfiguration = UIButton.Configuration.filled()
        systemRotationLandscapeButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        systemRotationLandscapeButtonConfiguration.cornerStyle = .capsule
        systemRotationLandscapeButtonConfiguration.attributedTitle = AttributedString(
            "全屏2",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            ])
        )
        systemRotationLandscapeButton.configuration = systemRotationLandscapeButtonConfiguration
        systemRotationLandscapeButton.translatesAutoresizingMaskIntoConstraints = false
        systemRotationLandscapeButton.addTarget(self, action: #selector(systemRotationLandscapeButtonTapped), for: .touchUpInside)

        view.addSubview(playerContainerView)
        playerContainerView.addSubview(playerView)
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(positionButton)
        buttonStackView.addArrangedSubview(landscapeButton)
        buttonStackView.addArrangedSubview(systemRotationLandscapeButton)

        playerContainerViewTopLayoutConstraint = playerContainerView.topAnchor.constraint(equalTo: view.topAnchor)
        playerContainerViewCenterLayoutConstraint = playerContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50)
        NSLayoutConstraint.activate([
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerViewCenterLayoutConstraint,
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 3.0 / 4.0),

            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),

            buttonStackView.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 30),
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        let testLabel = UILabel()
        testLabel.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        testLabel.text = "Test"
        playerView.addSubview(testLabel)
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        testLabel.centerXAnchor.constraint(equalTo: playerView.centerXAnchor).isActive = true
        testLabel.centerYAnchor.constraint(equalTo: playerView.centerYAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

//        if playerView.superview === playerContainerView {
//            playerView.frame = playerContainerView.bounds
//        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        shouldHideHomeIndicator
    }

    @objc private func positionButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()

        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        configuration.cornerStyle = .capsule
        playerContainerViewCenterLayoutConstraint.isActive = false
        playerContainerViewTopLayoutConstraint.isActive = false

        if sender.isSelected {
            configuration.attributedSubtitle = AttributedString(
                "中心",
                attributes: AttributeContainer([
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                ])
            )
            playerContainerViewTopLayoutConstraint.isActive = true
        } else {
            configuration.attributedSubtitle = AttributedString(
                "顶部",
                attributes: AttributeContainer([
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                ])
            )
            playerContainerViewCenterLayoutConstraint.isActive = true
        }
        sender.configuration = configuration

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func landscapeButtonTapped() {
        guard landscapeViewController == nil else {
            return
        }

        let landscapeViewController = LandscapeViewController()
        landscapeViewController.transitionContentView = playerView
        landscapeViewController.didTapUserInfoHandler = { [weak self] viewController in
            self?.pendingExitFullscreenTask = {
                self?.showUserInfo()
            }

            viewController.dismiss(animated: true)
        }

        let animationProvider = DefaultTransitionAnimationProvider()
        let transitionCoordinator = TransitionCoordinator(
            fromContextProvider: self,
            toContextProvider: landscapeViewController,
            fromInterfaceOrientation: .portrait,
            toInterfaceOrientation: .landscapeRight,
            animationProvider: animationProvider
        )

        self.landscapeViewController = landscapeViewController
        orientationTransitionCoordinator = transitionCoordinator

        landscapeViewController.modalPresentationStyle = .fullScreen
        landscapeViewController.transitioningDelegate = transitionCoordinator

        present(landscapeViewController, animated: true)
    }

    @objc private func systemRotationLandscapeButtonTapped() {
        guard landscapeViewController == nil else {
            return
        }

        let landscapeViewController = LandscapeViewController()
        landscapeViewController.transitionContentView = playerView
        landscapeViewController.didTapCloseHandler = { [weak self] _ in
            self?.systemRotationTransitionCoordinator?.dismiss()
        }
        landscapeViewController.didTapUserInfoHandler = { [weak self] _ in
            self?.pendingExitFullscreenTask = {
                self?.showUserInfo()
            }
            self?.systemRotationTransitionCoordinator?.dismiss()
        }

        let transitionCoordinator = SystemRotationTransitionCoordinator(
            fromContextProvider: self,
            toContextProvider: landscapeViewController,
            fromInterfaceOrientation: .portrait,
            toInterfaceOrientation: .landscapeRight
        )

        self.landscapeViewController = landscapeViewController
        systemRotationTransitionCoordinator = transitionCoordinator
        transitionCoordinator.present()
    }

    private func showUserInfo() {
        navigationController?.pushViewController(UserInfoViewController(), animated: true)
    }

    private func setHomeIndicatorHidden(_ isHidden: Bool) {
        shouldHideHomeIndicator = isHidden
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
}

extension HomeViewController: TransitionFromContextProvider {
    func transitionFromContextProviderViewController(_ contextProvider: TransitionFromContextProvider) -> UIViewController {
        self
    }

    func transitionFromContextProviderTransitionFrame(_ contextProvider: TransitionFromContextProvider, in containerView: UIView) -> CGRect {
        containerView.convert(playerContainerView.bounds, from: playerContainerView)
    }

    func transitionFromContextProviderPrepareTransitionView(_ contextProvider: TransitionFromContextProvider, transitionView: UIView) {
        movePlayerView(to: transitionView)
    }

    func transitionFromContextProviderAnimateAlongsideTransition(_ contextProvider: TransitionFromContextProvider, transitionView: UIView, animator: UIViewImplicitlyAnimating) {
        transitionView.clipsToBounds = true
        transitionView.layer.cornerRadius = 20
        animator.addAnimations? {
            transitionView.layer.cornerRadius = 0
        }
    }

    func transitionFromContextProviderFinishTransitionView(_ contextProvider: TransitionFromContextProvider) {
        movePlayerView(to: playerContainerView)
    }

    func transitionFromContextProviderMakePresentingSnapshotView(
        _ contextProvider: TransitionFromContextProvider,
        afterScreenUpdates: Bool
    ) -> UIView? {
        playerView.isHidden = true
        defer {
            playerView.isHidden = false
        }

        // snapshotView may reuse the previous render cache, so the temporary hidden playerView can still appear in it.
        view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        let snapshotView = UIImageView(image: image)
        snapshotView.frame = view.bounds
        return snapshotView
    }

    func transitionFromContextProviderTransitionWillEnter(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider) {
        setHomeIndicatorHidden(true)
    }

    func transitionFromContextProviderTransitionDidEnter(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider) {
        setHomeIndicatorHidden(false)
    }

    func transitionFromContextProviderTransitionWillExit(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider) {
        setHomeIndicatorHidden(true)
    }

    func transitionFromContextProviderTransitionDidExit(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider) {
        setHomeIndicatorHidden(false)
        orientationTransitionCoordinator = nil
        systemRotationTransitionCoordinator = nil
        landscapeViewController = nil

        pendingExitFullscreenTask?()
        pendingExitFullscreenTask = nil
    }

    private func movePlayerView(to containerView: UIView) {
        playerView.removeFromSuperview()
        playerView.transform = .identity
        playerView.frame = containerView.bounds
        playerView.translatesAutoresizingMaskIntoConstraints = false
//        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }
}
