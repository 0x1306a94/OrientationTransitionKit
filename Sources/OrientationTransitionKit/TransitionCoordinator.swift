import OSLog
import UIKit

/// Coordinates an orientation-changing transition between two view controllers.
///
/// The presented view controller must use `UIModalPresentationStyle.fullScreen`. Only full-screen presentations
/// remove the presenting view and let the system rotate the interface to the presented view controller's
/// `supportedInterfaceOrientations`; other styles keep the presenting orientation and break the transition.
@MainActor
@objc(OTKTransitionCoordinator)
@objcMembers
public final class TransitionCoordinator: NSObject {
    public let fromContextProvider: TransitionFromContextProvider
    public let toContextProvider: TransitionToContextProvider
    public let fromInterfaceOrientation: UIInterfaceOrientation
    public let toInterfaceOrientation: UIInterfaceOrientation
    /// Decides whether the transition rotates between `fromInterfaceOrientation` and `toInterfaceOrientation`.
    /// Return `false` in environments that ignore `supportedInterfaceOrientations` (such as iPad or the inner display
    /// of a foldable device) to keep the scene's current orientation during the transition.
    /// Treated as `true` when `nil` or when the window scene is unavailable.
    public var shouldRotateHandler: ((UIWindowScene) -> Bool)?

    private let animationProvider: TransitionAnimationProvider
    private weak var observedWindowScene: UIWindowScene?
    private var pendingTransitionIsPresenting = false
    private var sceneObservation: NSKeyValueObservation?
    private var fallbackWorkItem: DispatchWorkItem?
    private var resolvedFromInterfaceOrientation: UIInterfaceOrientation
    private var resolvedToInterfaceOrientation: UIInterfaceOrientation

    public init(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        animationProvider: TransitionAnimationProvider,
    ) {
        self.fromContextProvider = fromContextProvider
        self.toContextProvider = toContextProvider
        self.fromInterfaceOrientation = fromInterfaceOrientation
        self.toInterfaceOrientation = toInterfaceOrientation
        self.animationProvider = animationProvider
        resolvedFromInterfaceOrientation = fromInterfaceOrientation
        resolvedToInterfaceOrientation = toInterfaceOrientation
        super.init()
    }

    func finishTransitionLifecycle(
        isPresenting: Bool,
        transitionContext: UIViewControllerContextTransitioning,
    ) {
        let viewController = isPresenting
            ? toContextProvider.transitionToContextProviderViewController(toContextProvider)
            : fromContextProvider.transitionFromContextProviderViewController(fromContextProvider)
        let windowScene = viewController.view.window?.windowScene ?? transitionContext.containerView.window?.windowScene

        waitForExpectedOrientation(
            isPresenting: isPresenting,
            windowScene: windowScene,
            viewController: viewController,
        )
    }

    private func waitForExpectedOrientation(
        isPresenting: Bool,
        windowScene: UIWindowScene?,
        viewController: UIViewController,
    ) {
        stopObservingWindowScene()
        pendingTransitionIsPresenting = isPresenting

        let phase = transitionPhase(isPresenting: isPresenting)
        // No rotation is involved when both orientations match, so there is nothing to wait for
        if resolvedFromInterfaceOrientation == resolvedToInterfaceOrientation {
            Logger.transitionCoordinator.debug("[\(phase)] Same from and to orientation, finish immediately")
            notifyDidFinishTransition(isPresenting: isPresenting, windowScene: windowScene)
            return
        }

        guard let windowScene else {
            Logger.transitionCoordinator.notice("[\(phase)] Window scene not found, finish immediately")
            notifyDidFinishTransition(isPresenting: isPresenting, windowScene: nil)
            return
        }

        Logger.transitionCoordinator.debug(
            "[\(phase)] Animation completed, current: \(self.currentInterfaceOrientation(windowScene: windowScene).logDescription), expected: \(self.expectedInterfaceOrientation(isPresenting: isPresenting).logDescription)",
        )

        if isExpectedOrientation(windowScene: windowScene, isPresenting: isPresenting) {
            Logger.transitionCoordinator.debug("[\(phase)] Already in expected orientation")
            notifyDidFinishTransition(isPresenting: isPresenting, windowScene: windowScene)
            return
        }

        if #available(iOS 16.0, *) {
            viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }

        if isExpectedOrientation(windowScene: windowScene, isPresenting: isPresenting) {
            Logger.transitionCoordinator.debug("[\(phase)] Reached expected orientation after orientation update request")
            notifyDidFinishTransition(isPresenting: isPresenting, windowScene: windowScene)
            return
        }

        startObservingWindowSceneUntilExpectedOrientation(windowScene)
    }

    private func startObservingWindowSceneUntilExpectedOrientation(_ windowScene: UIWindowScene) {
        stopObservingWindowScene()

        observedWindowScene = windowScene
        if #available(iOS 16.0, *) {
            sceneObservation = windowScene.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    self?.handleWindowSceneChange()
                }
            }
        } else {
            sceneObservation = windowScene.observe(\.interfaceOrientation, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    self?.handleWindowSceneChange()
                }
            }
        }

        // Large-screen environments such as the iPhone Duo inner display and iPad ignore supportedInterfaceOrientations,
        // so the system never rotates; finish after a timeout
        let fallbackWorkItem = DispatchWorkItem { [weak self] in
            guard let self, let observedWindowScene else {
                return
            }

            Logger.transitionCoordinator.notice(
                "[\(self.transitionPhase(isPresenting: self.pendingTransitionIsPresenting))] Timeout, finish by fallback, current: \(self.currentInterfaceOrientation(windowScene: observedWindowScene).logDescription)",
            )
            finishPendingTransition()
        }
        self.fallbackWorkItem = fallbackWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: fallbackWorkItem)
        Logger.transitionCoordinator.debug("[\(self.transitionPhase(isPresenting: self.pendingTransitionIsPresenting))] Start observing window scene, timeout: 0.25s")

        notifyDidFinishIfExpectedOrientation()
    }

    private func stopObservingWindowScene() {
        sceneObservation?.invalidate()
        sceneObservation = nil
        observedWindowScene = nil
        fallbackWorkItem?.cancel()
        fallbackWorkItem = nil
    }

    private func handleWindowSceneChange() {
        if let observedWindowScene {
            Logger.transitionCoordinator.debug(
                "Window scene changed, current: \(self.currentInterfaceOrientation(windowScene: observedWindowScene).logDescription)",
            )
        }
        notifyDidFinishIfExpectedOrientation()
    }

    private func notifyDidFinishIfExpectedOrientation() {
        guard let observedWindowScene else {
            return
        }

        let phase = transitionPhase(isPresenting: pendingTransitionIsPresenting)
        guard isExpectedOrientation(windowScene: observedWindowScene, isPresenting: pendingTransitionIsPresenting) else {
            Logger.transitionCoordinator.debug(
                "[\(phase)] Orientation not expected yet, current: \(self.currentInterfaceOrientation(windowScene: observedWindowScene).logDescription)",
            )
            return
        }

        Logger.transitionCoordinator.debug("[\(phase)] Reached expected orientation while observing")
        finishPendingTransition()
    }

    private func finishPendingTransition() {
        guard let observedWindowScene else {
            return
        }

        stopObservingWindowScene()
        notifyDidFinishTransition(isPresenting: pendingTransitionIsPresenting, windowScene: observedWindowScene)
    }

    private func notifyDidFinishTransition(isPresenting: Bool, windowScene: UIWindowScene?) {
        let currentOrientation = windowScene.map { currentInterfaceOrientation(windowScene: $0).logDescription } ?? "nil"
        Logger.transitionCoordinator.debug(
            "[\(self.transitionPhase(isPresenting: isPresenting))] Notify did \(isPresenting ? "enter" : "exit"), current: \(currentOrientation)",
        )
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
        isPresenting: Bool,
    ) -> Bool {
        currentInterfaceOrientation(windowScene: windowScene) == expectedInterfaceOrientation(isPresenting: isPresenting)
    }

    private func currentInterfaceOrientation(windowScene: UIWindowScene) -> UIInterfaceOrientation {
        if #available(iOS 16.0, *) {
            return windowScene.effectiveGeometry.interfaceOrientation
        }
        return windowScene.interfaceOrientation
    }

    private func transitionPhase(isPresenting: Bool) -> String {
        isPresenting ? "present" : "dismiss"
    }

    private func expectedInterfaceOrientation(isPresenting: Bool) -> UIInterfaceOrientation {
        isPresenting ? resolvedToInterfaceOrientation : resolvedFromInterfaceOrientation
    }

    private func resolveInterfaceOrientations(isPresenting: Bool, windowScene: UIWindowScene?) {
        let shouldRotate = windowScene.map { shouldRotateHandler?($0) ?? true } ?? true
        let currentOrientation = windowScene.map { currentInterfaceOrientation(windowScene: $0) } ?? .unknown
        (resolvedFromInterfaceOrientation, resolvedToInterfaceOrientation) = Self.resolvedInterfaceOrientations(
            fromInterfaceOrientation: fromInterfaceOrientation,
            toInterfaceOrientation: toInterfaceOrientation,
            currentInterfaceOrientation: currentOrientation,
            shouldRotate: shouldRotate,
        )
        Logger.transitionCoordinator.debug(
            "[\(self.transitionPhase(isPresenting: isPresenting))] Resolve orientations, shouldRotate: \(shouldRotate), from: \(self.resolvedFromInterfaceOrientation.logDescription), to: \(self.resolvedToInterfaceOrientation.logDescription)",
        )
    }

    static func resolvedInterfaceOrientations(
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        currentInterfaceOrientation: UIInterfaceOrientation,
        shouldRotate: Bool,
    ) -> (from: UIInterfaceOrientation, to: UIInterfaceOrientation) {
        guard !shouldRotate, currentInterfaceOrientation != .unknown else {
            return (fromInterfaceOrientation, toInterfaceOrientation)
        }
        return (currentInterfaceOrientation, currentInterfaceOrientation)
    }

    private func makeAnimator(isPresenting: Bool) -> TransitionAnimator {
        TransitionAnimator(
            isPresenting: isPresenting,
            fromContextProvider: fromContextProvider,
            toContextProvider: toContextProvider,
            fromInterfaceOrientation: resolvedFromInterfaceOrientation,
            toInterfaceOrientation: resolvedToInterfaceOrientation,
            animationProvider: animationProvider,
            transitionCoordinator: self,
        )
    }
}

extension TransitionCoordinator: UIViewControllerTransitioningDelegate {
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source _: UIViewController,
    ) -> UIViewControllerAnimatedTransitioning? {
        if presented.modalPresentationStyle != .fullScreen {
            Logger.transitionCoordinator.fault(
                "Only UIModalPresentationStyle.fullScreen is supported, got rawValue: \(presented.modalPresentationStyle.rawValue)",
            )
            assertionFailure("TransitionCoordinator only supports UIModalPresentationStyle.fullScreen")
        }
        resolveInterfaceOrientations(isPresenting: true, windowScene: presenting.view.window?.windowScene)
        return makeAnimator(isPresenting: true)
    }

    public func animationController(
        forDismissed dismissed: UIViewController,
    ) -> UIViewControllerAnimatedTransitioning? {
        resolveInterfaceOrientations(isPresenting: false, windowScene: dismissed.view.window?.windowScene)
        return makeAnimator(isPresenting: false)
    }
}
