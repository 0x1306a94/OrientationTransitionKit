import UIKit

@MainActor
@objc(OTKTransitionToContextProvider)
public protocol TransitionToContextProvider: NSObjectProtocol {
    /// Returns the fullscreen-side view controller that owns this provider.
    /// - Parameter contextProvider: The provider instance receiving this callback.
    func transitionToContextProviderViewController(_ contextProvider: TransitionToContextProvider) -> UIViewController

    /// Returns the target frame for the transition view in the transition container.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - containerView: The UIKit transition container view.
    func transitionToContextProviderTransitionFrame(_ contextProvider: TransitionToContextProvider, in containerView: UIView) -> CGRect

    /// Gives the provider a temporary transition view before the animation starts.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - transitionView: The view that should host the moving transition content.
    func transitionToContextProviderPrepareTransitionView(_ contextProvider: TransitionToContextProvider, transitionView: UIView)

    /// Gives the provider the temporary transition view and animator so it can animate alongside the transition.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - transitionView: The view that hosts the moving transition content.
    ///   - animator: The animator used by the transition.
    @objc optional func transitionToContextProviderAnimateAlongsideTransition(
        _ contextProvider: TransitionToContextProvider,
        transitionView: UIView,
        animator: UIViewImplicitlyAnimating
    )

    /// Notifies the provider that its content should be restored to the final fullscreen container.
    /// - Parameter contextProvider: The provider instance receiving this callback.
    func transitionToContextProviderFinishTransitionView(_ contextProvider: TransitionToContextProvider)

    /// Called before entering this fullscreen context.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - fromContextProvider: The source portrait context provider.
    @objc optional func transitionToContextProviderTransitionWillEnter(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider)

    /// Called after this fullscreen context has entered and orientation handling has completed.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - fromContextProvider: The source portrait context provider.
    @objc optional func transitionToContextProviderTransitionDidEnter(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider)

    /// Called before exiting this fullscreen context.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - fromContextProvider: The source portrait context provider.
    @objc optional func transitionToContextProviderTransitionWillExit(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider)

    /// Called after this fullscreen context has exited and orientation handling has completed.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - fromContextProvider: The source portrait context provider.
    @objc optional func transitionToContextProviderTransitionDidExit(_ contextProvider: TransitionToContextProvider, from fromContextProvider: TransitionFromContextProvider)
}
