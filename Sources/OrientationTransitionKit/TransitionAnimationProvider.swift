import UIKit

@MainActor
@objc(OTKTransitionAnimationProvider)
public protocol TransitionAnimationProvider: NSObjectProtocol {
    func transitionAnimationProviderPresentAnimator(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating

    func transitionAnimationProviderDismissAnimator(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating
}
