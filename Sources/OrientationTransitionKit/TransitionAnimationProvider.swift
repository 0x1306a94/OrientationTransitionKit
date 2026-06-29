import UIKit

@MainActor
@objc(OTKTransitionAnimationProvider)
public protocol TransitionAnimationProvider: NSObjectProtocol {
    /// Creates the animator used when presenting the fullscreen context.
    /// - Parameters:
    ///   - animationProvider: The provider instance receiving this callback.
    ///   - fromContextProvider: The source portrait context provider.
    ///   - toContextProvider: The target fullscreen context provider.
    ///   - fromInterfaceOrientation: The interface orientation before presentation starts.
    ///   - toInterfaceOrientation: The expected interface orientation after presentation completes.
    ///   - transitionContext: UIKit's transition context.
    func transitionAnimationProviderPresentAnimator(
        _ animationProvider: TransitionAnimationProvider,
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating

    /// Creates the animator used when dismissing the fullscreen context.
    /// - Parameters:
    ///   - animationProvider: The provider instance receiving this callback.
    ///   - fromContextProvider: The source portrait context provider.
    ///   - toContextProvider: The target fullscreen context provider.
    ///   - fromInterfaceOrientation: The interface orientation before dismissal starts.
    ///   - toInterfaceOrientation: The expected interface orientation after dismissal completes.
    ///   - transitionContext: UIKit's transition context.
    func transitionAnimationProviderDismissAnimator(
        _ animationProvider: TransitionAnimationProvider,
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating
}
