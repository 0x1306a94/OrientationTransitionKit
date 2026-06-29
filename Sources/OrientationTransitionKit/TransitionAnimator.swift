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
    }

    private static func finishTransition(
        _ transitionContext: UIViewControllerContextTransitioning,
        finalPosition: UIViewAnimatingPosition,
        isPresenting: Bool,
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        transitionCoordinator: TransitionCoordinator?
    ) {
        let success = finalPosition == .end && !transitionContext.transitionWasCancelled
        transitionContext.completeTransition(success)

        guard success else {
            return
        }

        transitionCoordinator?.finishTransitionLifecycle(
            isPresenting: isPresenting,
            transitionContext: transitionContext
        )
    }
}
