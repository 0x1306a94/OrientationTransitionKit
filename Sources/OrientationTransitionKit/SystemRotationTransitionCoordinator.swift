import UIKit

@objc(OTKSystemRotationTransitionState)
public enum SystemRotationTransitionState: Int {
    case idle
    case presenting
    case presented
    case dismissing
}

@MainActor
@objc(OTKSystemRotationTransitionCoordinator)
@objcMembers
public final class SystemRotationTransitionCoordinator: NSObject {
    public let fromContextProvider: TransitionFromContextProvider
    public let toContextProvider: TransitionToContextProvider
    public let fromInterfaceOrientation: UIInterfaceOrientation
    public let toInterfaceOrientation: UIInterfaceOrientation
    public private(set) var state: SystemRotationTransitionState = .idle

    private var transitionViewController: SystemRotationTransitionViewController?
    private var activeInterfaceOrientation: UIInterfaceOrientation

    public init(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation
    ) {
        self.fromContextProvider = fromContextProvider
        self.toContextProvider = toContextProvider
        self.fromInterfaceOrientation = fromInterfaceOrientation
        self.toInterfaceOrientation = toInterfaceOrientation
        self.activeInterfaceOrientation = fromInterfaceOrientation
        super.init()
    }

    public func present() {
        guard state == .idle else {
            return
        }

        let presentingViewController = fromContextProvider.transitionFromContextProviderViewController(fromContextProvider)
        let presentedViewController = toContextProvider.transitionToContextProviderViewController(toContextProvider)
        let presentingSnapshotView = makePresentingSnapshotView(from: presentingViewController, afterScreenUpdates: false)
        let transitionViewController = SystemRotationTransitionViewController(
            contentViewController: presentedViewController,
            presentingSnapshotView: presentingSnapshotView,
            coordinator: self
        )
        transitionViewController.modalPresentationStyle = .fullScreen
        self.transitionViewController = transitionViewController

        state = .presenting
        fromContextProvider.transitionFromContextProviderTransitionWillEnter?(fromContextProvider, to: toContextProvider)
        toContextProvider.transitionToContextProviderTransitionWillEnter?(toContextProvider, from: fromContextProvider)

        presentingViewController.present(transitionViewController, animated: false) { [weak self, weak transitionViewController] in
            guard let self, let transitionViewController else {
                return
            }

            transitionViewController.prepareForPresentTransition()
            self.requestInterfaceOrientation(self.toInterfaceOrientation, using: transitionViewController)
        }
    }

    public func dismiss() {
        guard
            state == .presented,
            let transitionViewController
        else {
            return
        }

        state = .dismissing
        toContextProvider.transitionToContextProviderTransitionWillExit?(toContextProvider, from: fromContextProvider)
        fromContextProvider.transitionFromContextProviderTransitionWillExit?(fromContextProvider, to: toContextProvider)
        transitionViewController.prepareForDismissTransition()
        requestInterfaceOrientation(fromInterfaceOrientation, using: transitionViewController)
    }

    fileprivate func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        interfaceOrientationMask(for: activeInterfaceOrientation)
    }

    fileprivate func didFinishPresentTransition() {
        guard state == .presenting else {
            return
        }

        state = .presented
        toContextProvider.transitionToContextProviderTransitionDidEnter?(toContextProvider, from: fromContextProvider)
        fromContextProvider.transitionFromContextProviderTransitionDidEnter?(fromContextProvider, to: toContextProvider)
    }

    fileprivate func didFinishDismissTransition() {
        guard
            state == .dismissing,
            let transitionViewController
        else {
            return
        }

        transitionViewController.dismiss(animated: false) { [weak self] in
            guard let self else {
                return
            }

            self.fromContextProvider.transitionFromContextProviderTransitionDidExit?(self.fromContextProvider, to: self.toContextProvider)
            self.toContextProvider.transitionToContextProviderTransitionDidExit?(self.toContextProvider, from: self.fromContextProvider)
            self.state = .idle
            self.transitionViewController = nil
        }
    }

    private func makePresentingSnapshotView(
        from presentingViewController: UIViewController,
        afterScreenUpdates: Bool
    ) -> UIView? {
        if let snapshotView = fromContextProvider.transitionFromContextProviderMakePresentingSnapshotView?(
            fromContextProvider,
            afterScreenUpdates: afterScreenUpdates
        ) {
            return snapshotView
        }

        return presentingViewController.view.snapshotView(afterScreenUpdates: afterScreenUpdates)
    }

    private func requestInterfaceOrientation(
        _ interfaceOrientation: UIInterfaceOrientation,
        using viewController: UIViewController
    ) {
        activeInterfaceOrientation = interfaceOrientation

        if #available(iOS 16.0, *), let windowScene = viewController.view.window?.windowScene {
            viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
            let preferences = UIWindowScene.GeometryPreferences.iOS(
                interfaceOrientations: interfaceOrientationMask(for: interfaceOrientation)
            )
            windowScene.requestGeometryUpdate(preferences) { _ in }
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private func interfaceOrientationMask(for interfaceOrientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
        switch interfaceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .unknown:
            return .all
        @unknown default:
            return .all
        }
    }
}

@MainActor
private final class SystemRotationTransitionViewController: UIViewController {
    private let contentViewController: UIViewController
    private var presentingSnapshotView: UIView?
    private weak var coordinator: SystemRotationTransitionCoordinator?
    private let transitionContainerView = UIView()
    private var transitionDirection: SystemRotationTransitionDirection?

    init(
        contentViewController: UIViewController,
        presentingSnapshotView: UIView?,
        coordinator: SystemRotationTransitionCoordinator
    ) {
        self.contentViewController = contentViewController
        self.presentingSnapshotView = presentingSnapshotView
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.isHidden = true
        transitionContainerView.clipsToBounds = true

        insertPresentingSnapshotIfNeeded()

        addChild(contentViewController)
        contentViewController.view.frame = view.bounds
        contentViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        coordinator?.supportedInterfaceOrientations() ?? .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        coordinator?.fromInterfaceOrientation ?? .portrait
    }

    func prepareForPresentTransition() {
        guard let coordinator else {
            return
        }

        view.layoutIfNeeded()
        contentViewController.view.alpha = 0
        transitionDirection = .enter
        transitionContainerView.frame = coordinator.fromContextProvider.transitionFromContextProviderTransitionFrame(
            coordinator.fromContextProvider,
            in: view
        )
        view.addSubview(transitionContainerView)
        coordinator.fromContextProvider.transitionFromContextProviderPrepareTransitionView(
            coordinator.fromContextProvider,
            transitionView: transitionContainerView
        )
        transitionContainerView.setNeedsLayout()
        transitionContainerView.layoutIfNeeded()
        view.isHidden = false
    }

    func prepareForDismissTransition() {
        guard let coordinator else {
            return
        }

        view.isHidden = true
        view.layoutIfNeeded()
        contentViewController.view.alpha = 0
        presentingSnapshotView?.removeFromSuperview()
        insertPresentingSnapshotIfNeeded()
        applyPresentingSnapshotCompensation(size: view.bounds.size, interfaceOrientation: coordinator.toInterfaceOrientation)
        transitionDirection = .exit
        transitionContainerView.frame = coordinator.toContextProvider.transitionToContextProviderTransitionFrame(
            coordinator.toContextProvider,
            in: view
        )
        view.addSubview(transitionContainerView)
        coordinator.toContextProvider.transitionToContextProviderPrepareTransitionView(
            coordinator.toContextProvider,
            transitionView: transitionContainerView
        )
        transitionContainerView.setNeedsLayout()
        transitionContainerView.layoutIfNeeded()
        view.isHidden = false
    }

    override func viewWillTransition(
        to size: CGSize,
        with transitionCoordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: transitionCoordinator)

        let direction = transitionDirection
        transitionCoordinator.animate { [weak self] _ in
            guard let self else {
                return
            }

            self.contentViewController.view.frame = CGRect(origin: .zero, size: size)
            self.contentViewController.view.setNeedsLayout()
            self.contentViewController.view.layoutIfNeeded()
            self.applyPresentingSnapshotCompensation(size: size, direction: direction)
            self.transitionContainerView.frame = self.targetFrame(for: direction)
            self.transitionContainerView.setNeedsLayout()
            self.transitionContainerView.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.finishTransition(for: direction)
        }
    }

    private func targetFrame(for direction: SystemRotationTransitionDirection?) -> CGRect {
        guard let coordinator else {
            return transitionContainerView.frame
        }

        switch direction {
        case .enter:
            return coordinator.toContextProvider.transitionToContextProviderTransitionFrame(
                coordinator.toContextProvider,
                in: view
            )
        case .exit:
            return coordinator.fromContextProvider.transitionFromContextProviderTransitionFrame(
                coordinator.fromContextProvider,
                in: view
            )
        case nil:
            return transitionContainerView.frame
        }
    }

    private func insertPresentingSnapshotIfNeeded() {
        guard
            let presentingSnapshotView,
            presentingSnapshotView.superview == nil
        else {
            return
        }

        presentingSnapshotView.transform = .identity
        presentingSnapshotView.frame = view.bounds
        presentingSnapshotView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(presentingSnapshotView, at: 0)
    }

    private func applyPresentingSnapshotCompensation(
        size: CGSize,
        direction: SystemRotationTransitionDirection?
    ) {
        guard let coordinator else {
            return
        }

        let interfaceOrientation: UIInterfaceOrientation
        switch direction {
        case .enter:
            interfaceOrientation = coordinator.toInterfaceOrientation
        case .exit:
            interfaceOrientation = coordinator.fromInterfaceOrientation
        case nil:
            return
        }

        applyPresentingSnapshotCompensation(size: size, interfaceOrientation: interfaceOrientation)
    }

    private func applyPresentingSnapshotCompensation(
        size: CGSize,
        interfaceOrientation: UIInterfaceOrientation
    ) {
        guard
            let presentingSnapshotView,
            let coordinator
        else {
            return
        }

        let rotationAngle = self.rotationAngle(
            from: coordinator.fromInterfaceOrientation,
            to: interfaceOrientation
        )
        let snapshotSize: CGSize
        if abs(rotationAngle) == .pi / 2 {
            snapshotSize = CGSize(width: size.height, height: size.width)
        } else {
            snapshotSize = size
        }

        presentingSnapshotView.bounds = CGRect(
            origin: .zero,
            size: snapshotSize
        )
        presentingSnapshotView.center = CGPoint(x: size.width / 2, y: size.height / 2)
        presentingSnapshotView.transform = CGAffineTransform(rotationAngle: -rotationAngle)
    }

    private func finishTransition(for direction: SystemRotationTransitionDirection?) {
        guard let coordinator else {
            return
        }

        switch direction {
        case .enter:
            coordinator.toContextProvider.transitionToContextProviderFinishTransitionView(coordinator.toContextProvider)
            contentViewController.view.alpha = 1
            presentingSnapshotView?.removeFromSuperview()
            transitionContainerView.removeFromSuperview()
            transitionDirection = nil
            coordinator.didFinishPresentTransition()
        case .exit:
            coordinator.fromContextProvider.transitionFromContextProviderFinishTransitionView(coordinator.fromContextProvider)
            transitionContainerView.removeFromSuperview()
            transitionDirection = nil
            coordinator.didFinishDismissTransition()
        case nil:
            return
        }
    }

    private func rotationAngle(
        from fromInterfaceOrientation: UIInterfaceOrientation,
        to toInterfaceOrientation: UIInterfaceOrientation
    ) -> CGFloat {
        normalizedRotationAngle(
            angle(for: toInterfaceOrientation) - angle(for: fromInterfaceOrientation)
        )
    }

    private func normalizedRotationAngle(_ rotationAngle: CGFloat) -> CGFloat {
        if rotationAngle > .pi {
            return rotationAngle - 2 * .pi
        }
        if rotationAngle < -.pi {
            return rotationAngle + 2 * .pi
        }
        return rotationAngle
    }

    private func angle(for interfaceOrientation: UIInterfaceOrientation) -> CGFloat {
        switch interfaceOrientation {
        case .portrait:
            return 0
        case .landscapeRight:
            return .pi / 2
        case .landscapeLeft:
            return -.pi / 2
        case .portraitUpsideDown:
            return .pi
        case .unknown:
            return 0
        @unknown default:
            return 0
        }
    }
}

private enum SystemRotationTransitionDirection {
    case enter
    case exit
}
