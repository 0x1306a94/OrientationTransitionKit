import UIKit

@MainActor
@objc(OTKTransitionToContextProvider)
public protocol TransitionToContextProvider: NSObjectProtocol {
    func transitionToContextProviderViewController() -> UIViewController
    func transitionToContextProviderTransitionFrame(in containerView: UIView) -> CGRect
    func transitionToContextProviderPrepareTransitionView(_ transitionView: UIView)
    func transitionToContextProviderFinishTransitionView()

    @objc optional func transitionToContextProviderTransitionWillEnter(from contextProvider: TransitionFromContextProvider)
    @objc optional func transitionToContextProviderTransitionDidEnter(from contextProvider: TransitionFromContextProvider)
    @objc optional func transitionToContextProviderTransitionWillExit(from contextProvider: TransitionFromContextProvider)
    @objc optional func transitionToContextProviderTransitionDidExit(from contextProvider: TransitionFromContextProvider)
}
