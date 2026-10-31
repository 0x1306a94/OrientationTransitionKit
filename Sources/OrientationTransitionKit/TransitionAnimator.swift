import OSLog
import UIKit

@MainActor
final class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let fromContextProvider: TransitionFromContextProvider
    private let toContextProvider: TransitionToContextProvider
    private let fromInterfaceOrientation: UIInterfaceOrientation
    private let toInterfaceOrientation: UIInterfaceOrientation
    private let animationProvider: TransitionAnimationProvider
    private weak var transitionCoordinator: TransitionCoordinator?

    init(
        isPresenting: Bool,
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        animationProvider: TransitionAnimationProvider,
        transitionCoordinator: TransitionCoordinator
    ) {
        self.isPresenting = isPresenting
        self.fromContextProvider = fromContextProvider
        self.toContextProvider = toContextProvider
        self.fromInterfaceOrientation = fromInterfaceOrientation
        self.toInterfaceOrientation = toInterfaceOrientation
        self.animationProvider = animationProvider
        self.transitionCoordinator = transitionCoordinator
        super.init()
    }

    nonisolated func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        0
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        Logger.transitionAnimator.debug(
            "[\(self.isPresenting ? "present" : "dismiss")] Animate transition, from: \(self.fromInterfaceOrientation.logDescription), to: \(self.toInterfaceOrientation.logDescription), container: \(transitionContext.containerView.bounds.debugDescription)",
        )

        let animator: UIViewImplicitlyAnimating
        if isPresenting {
            fromContextProvider.transitionFromContextProviderTransitionWillEnter?(fromContextProvider, to: toContextProvider)
            toContextProvider.transitionToContextProviderTransitionWillEnter?(toContextProvider, from: fromContextProvider)
            animator = animationProvider.transitionAnimationProviderPresentAnimator(
                animationProvider,
                fromContextProvider: fromContextProvider,
                toContextProvider: toContextProvider,
                fromInterfaceOrientation: fromInterfaceOrientation,
                toInterfaceOrientation: toInterfaceOrientation,
                transitionContext: transitionContext
            )
        } else {
            toContextProvider.transitionToContextProviderTransitionWillExit?(toContextProvider, from: fromContextProvider)
            fromContextProvider.transitionFromContextProviderTransitionWillExit?(fromContextProvider, to: toContextProvider)
            animator = animationProvider.transitionAnimationProviderDismissAnimator(
                animationProvider,
                fromContextProvider: fromContextProvider,
                toContextProvider: toContextProvider,
                fromInterfaceOrientation: fromInterfaceOrientation,
                toInterfaceOrientation: toInterfaceOrientation,
                transitionContext: transitionContext
            )
        }

        let fromContextProvider = fromContextProvider
        let toContextProvider = toContextProvider
        let transitionCoordinator = transitionCoordinator
        let completion: (UIViewAnimatingPosition) -> Void = { [isPresenting] finalPosition in
            Self.finishTransition(
                transitionContext,
                finalPosition: finalPosition,
                isPresenting: isPresenting,
                fromContextProvider: fromContextProvider,
                toContextProvider: toContextProvider,
                transitionCoordinator: transitionCoordinator
            )
        }

        if let addCompletion = animator.addCompletion {
            addCompletion(completion)
        }
        animator.startAnimation()
        Logger.transitionAnimator.debug("[\(self.isPresenting ? "present" : "dismiss")] Start animation")
    }

    private static func finishTransition(
        _ transitionContext: UIViewControllerContextTransitioning,
        finalPosition: UIViewAnimatingPosition,
        isPresenting: Bool,
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        transitionCoordinator: TransitionCoordinator?
    ) {
        let phase = isPresenting ? "present" : "dismiss"
        let success = finalPosition == .end && !transitionContext.transitionWasCancelled
        Logger.transitionAnimator.debug(
            "[\(phase)] Animation finished, position: \(finalPosition.logDescription), cancelled: \(transitionContext.transitionWasCancelled), success: \(success)",
        )
        transitionContext.completeTransition(success)

        guard success else {
            Logger.transitionAnimator.notice("[\(phase)] Transition not completed, skip lifecycle")
            return
        }

        guard let transitionCoordinator else {
            Logger.transitionAnimator.notice("[\(phase)] Transition coordinator released, skip lifecycle")
            return
        }

        transitionCoordinator.finishTransitionLifecycle(
            isPresenting: isPresenting,
            transitionContext: transitionContext
        )
    }
}
