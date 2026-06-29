import UIKit

@MainActor
@objc(OTKTransitionFromContextProvider)
public protocol TransitionFromContextProvider: NSObjectProtocol {
    /// Returns the portrait-side view controller that owns this provider.
    /// - Parameter contextProvider: The provider instance receiving this callback.
    func transitionFromContextProviderViewController(_ contextProvider: TransitionFromContextProvider) -> UIViewController

    /// Returns the source frame for the transition view in the transition container.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - containerView: The UIKit transition container view.
    func transitionFromContextProviderTransitionFrame(_ contextProvider: TransitionFromContextProvider, in containerView: UIView) -> CGRect

    /// Gives the provider a temporary transition view before the animation starts.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - transitionView: The view that should host the moving transition content.
    func transitionFromContextProviderPrepareTransitionView(_ contextProvider: TransitionFromContextProvider, transitionView: UIView)

    /// Notifies the provider that its content should be restored to the final portrait container.
    /// - Parameter contextProvider: The provider instance receiving this callback.
    func transitionFromContextProviderFinishTransitionView(_ contextProvider: TransitionFromContextProvider)

    /// Called before entering the target fullscreen context.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - toContextProvider: The target fullscreen context provider.
    @objc optional func transitionFromContextProviderTransitionWillEnter(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider)

    /// Called after the target fullscreen context has entered and orientation handling has completed.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - toContextProvider: The target fullscreen context provider.
    @objc optional func transitionFromContextProviderTransitionDidEnter(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider)

    /// Called before exiting the target fullscreen context.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - toContextProvider: The target fullscreen context provider.
    @objc optional func transitionFromContextProviderTransitionWillExit(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider)

    /// Called after exiting the target fullscreen context and orientation handling has completed.
    /// - Parameters:
    ///   - contextProvider: The provider instance receiving this callback.
    ///   - toContextProvider: The target fullscreen context provider.
    @objc optional func transitionFromContextProviderTransitionDidExit(_ contextProvider: TransitionFromContextProvider, to toContextProvider: TransitionToContextProvider)
}
