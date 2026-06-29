import UIKit

@MainActor
@objc(OTKTransitionCoordinator)
@objcMembers
public final class TransitionCoordinator: NSObject {
    public let fromContextProvider: TransitionFromContextProvider
    public let toContextProvider: TransitionToContextProvider
    public let fromInterfaceOrientation: UIInterfaceOrientation
    public let toInterfaceOrientation: UIInterfaceOrientation

    private let animationProvider: TransitionAnimationProvider
    private weak var observedWindowScene: UIWindowScene?
    private var observingEffectiveGeometry = false
    private var pendingTransitionIsPresenting = false
    private var sceneObservation: NSKeyValueObservation?

    public init(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        animationProvider: TransitionAnimationProvider
    ) {
        self.fromContextProvider = fromContextProvider
        self.toContextProvider = toContextProvider
        self.fromInterfaceOrientation = fromInterfaceOrientation
        self.toInterfaceOrientation = toInterfaceOrientation
        self.animationProvider = animationProvider
        super.init()
    }

    func finishTransitionLifecycle(
        isPresenting: Bool,
        transitionContext: UIViewControllerContextTransitioning
    ) {
        let viewController = isPresenting
            ? toContextProvider.transitionToContextProviderViewController(toContextProvider)
            : fromContextProvider.transitionFromContextProviderViewController(fromContextProvider)
        let windowScene = viewController.view.window?.windowScene ?? transitionContext.containerView.window?.windowScene

        waitForExpectedOrientation(
            isPresenting: isPresenting,
            windowScene: windowScene,
            viewController: viewController
        )
    }

    private func waitForExpectedOrientation(
        isPresenting: Bool,
        windowScene: UIWindowScene?,
        viewController: UIViewController
    ) {
        pendingTransitionIsPresenting = isPresenting

        guard let windowScene else {
            notifyDidFinishTransition(isPresenting: isPresenting)
            return
        }

        if isExpectedOrientation(windowScene: windowScene, isPresenting: isPresenting) {
            notifyDidFinishTransition(isPresenting: isPresenting)
            return
        }

        if #available(iOS 16.0, *) {
            viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
            let preferences = UIWindowScene.GeometryPreferences.iOS(
                interfaceOrientations: interfaceOrientationMask(for: expectedInterfaceOrientation(isPresenting: isPresenting))
            )
            windowScene.requestGeometryUpdate(preferences) { _ in }
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }

        if isExpectedOrientation(windowScene: windowScene, isPresenting: isPresenting) {
            notifyDidFinishTransition(isPresenting: isPresenting)
            return
        }

        startObservingWindowSceneUntilExpectedOrientation(windowScene)
    }

    private func startObservingWindowSceneUntilExpectedOrientation(_ windowScene: UIWindowScene) {
        stopObservingWindowScene()

        observedWindowScene = windowScene
        if #available(iOS 16.0, *) {
            observingEffectiveGeometry = true
            sceneObservation = windowScene.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.notifyDidFinishIfExpectedOrientation()
                }
            }
        } else {
            observingEffectiveGeometry = false
            sceneObservation = windowScene.observe(\.interfaceOrientation, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.notifyDidFinishIfExpectedOrientation()
                }
            }
        }

        notifyDidFinishIfExpectedOrientation()
    }

    private func stopObservingWindowScene() {
        sceneObservation?.invalidate()
        sceneObservation = nil
        observedWindowScene = nil
    }

    private func notifyDidFinishIfExpectedOrientation() {
        guard
            let observedWindowScene,
            isExpectedOrientation(windowScene: observedWindowScene, isPresenting: pendingTransitionIsPresenting)
        else {
            return
        }

        stopObservingWindowScene()
        notifyDidFinishTransition(isPresenting: pendingTransitionIsPresenting)
    }

    private func notifyDidFinishTransition(isPresenting: Bool) {
        if isPresenting {
            toContextProvider.transitionToContextProviderTransitionDidEnter?(toContextProvider, from: fromContextProvider)
            fromContextProvider.transitionFromContextProviderTransitionDidEnter?(fromContextProvider, to: toContextProvider)
        } else {
            fromContextProvider.transitionFromContextProviderTransitionDidExit?(fromContextProvider, to: toContextProvider)
            toContextProvider.transitionToContextProviderTransitionDidExit?(toContextProvider, from: fromContextProvider)
        }
    }

    private func isExpectedOrientation(
        windowScene: UIWindowScene,
        isPresenting: Bool
    ) -> Bool {
        currentInterfaceOrientation(windowScene: windowScene) == expectedInterfaceOrientation(isPresenting: isPresenting)
    }

    private func currentInterfaceOrientation(windowScene: UIWindowScene) -> UIInterfaceOrientation {
        if #available(iOS 16.0, *) {
            return windowScene.effectiveGeometry.interfaceOrientation
        }
        return windowScene.interfaceOrientation
    }

    private func expectedInterfaceOrientation(isPresenting: Bool) -> UIInterfaceOrientation {
        isPresenting ? toInterfaceOrientation : fromInterfaceOrientation
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

extension TransitionCoordinator: UIViewControllerTransitioningDelegate {
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return TransitionAnimator(
            isPresenting: true,
            fromContextProvider: fromContextProvider,
            toContextProvider: toContextProvider,
            fromInterfaceOrientation: fromInterfaceOrientation,
            toInterfaceOrientation: toInterfaceOrientation,
            animationProvider: animationProvider,
            transitionCoordinator: self
        )
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return TransitionAnimator(
            isPresenting: false,
            fromContextProvider: fromContextProvider,
            toContextProvider: toContextProvider,
            fromInterfaceOrientation: fromInterfaceOrientation,
            toInterfaceOrientation: toInterfaceOrientation,
            animationProvider: animationProvider,
            transitionCoordinator: self
        )
    }
}
