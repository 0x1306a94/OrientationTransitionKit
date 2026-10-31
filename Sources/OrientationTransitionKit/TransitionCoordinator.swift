import OSLog
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
    private var pendingTransitionIsPresenting = false
    private var sceneObservation: NSKeyValueObservation?
    private var fallbackWorkItem: DispatchWorkItem?

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
        guard let windowScene else {
            Logger.transitionCoordinator.notice("[\(phase)] Window scene not found, finish immediately")
            notifyDidFinishTransition(isPresenting: isPresenting)
            return
        }

        Logger.transitionCoordinator.debug(
            "[\(phase)] Animation completed, current: \(self.currentInterfaceOrientation(windowScene: windowScene).logDescription), expected: \(self.expectedInterfaceOrientation(isPresenting: isPresenting).logDescription)",
        )

        if isExpectedOrientation(windowScene: windowScene, isPresenting: isPresenting) {
            Logger.transitionCoordinator.debug("[\(phase)] Already in expected orientation")
            notifyDidFinishTransition(isPresenting: isPresenting)
            return
        }

        if #available(iOS 16.0, *) {
            viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }

        if isExpectedOrientation(windowScene: windowScene, isPresenting: isPresenting) {
            Logger.transitionCoordinator.debug("[\(phase)] Reached expected orientation after orientation update request")
            notifyDidFinishTransition(isPresenting: isPresenting)
            return
        }

        startObservingWindowSceneUntilExpectedOrientation(windowScene)
    }

    private func startObservingWindowSceneUntilExpectedOrientation(_ windowScene: UIWindowScene) {
        stopObservingWindowScene()

        observedWindowScene = windowScene
        if #available(iOS 16.0, *) {
            sceneObservation = windowScene.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.notifyDidFinishIfExpectedOrientation()
                }
            }
        } else {
            sceneObservation = windowScene.observe(\.interfaceOrientation, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.notifyDidFinishIfExpectedOrientation()
                }
            }
        }

        // 内屏、iPad 等大屏环境不受 supportedInterfaceOrientations 约束，系统不会旋转，超时后直接结束
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
        guard observedWindowScene != nil else {
            return
        }

        stopObservingWindowScene()
        notifyDidFinishTransition(isPresenting: pendingTransitionIsPresenting)
    }

    private func notifyDidFinishTransition(isPresenting: Bool) {
        Logger.transitionCoordinator.debug("[\(self.transitionPhase(isPresenting: isPresenting))] Notify did \(isPresenting ? "enter" : "exit")")
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
        isPresenting ? toInterfaceOrientation : fromInterfaceOrientation
    }
}

extension TransitionCoordinator: UIViewControllerTransitioningDelegate {
    public func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController,
    ) -> UIViewControllerAnimatedTransitioning? {
        TransitionAnimator(
            isPresenting: true,
            fromContextProvider: fromContextProvider,
            toContextProvider: toContextProvider,
            fromInterfaceOrientation: fromInterfaceOrientation,
            toInterfaceOrientation: toInterfaceOrientation,
            animationProvider: animationProvider,
            transitionCoordinator: self,
        )
    }

    public func animationController(
        forDismissed _: UIViewController,
    ) -> UIViewControllerAnimatedTransitioning? {
        TransitionAnimator(
            isPresenting: false,
            fromContextProvider: fromContextProvider,
            toContextProvider: toContextProvider,
            fromInterfaceOrientation: fromInterfaceOrientation,
            toInterfaceOrientation: toInterfaceOrientation,
            animationProvider: animationProvider,
            transitionCoordinator: self,
        )
    }
}
