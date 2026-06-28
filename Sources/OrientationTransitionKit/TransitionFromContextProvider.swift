import UIKit

@MainActor
@objc(OTKTransitionFromContextProvider)
public protocol TransitionFromContextProvider: NSObjectProtocol {
    func transitionFromContextProviderViewController() -> UIViewController
    func transitionFromContextProviderTransitionFrame(in containerView: UIView) -> CGRect
    func transitionFromContextProviderPrepareTransitionView(_ transitionView: UIView)
    func transitionFromContextProviderFinishTransitionView()

    @objc optional func transitionFromContextProviderTransitionWillEnter(to contextProvider: TransitionToContextProvider)
    @objc optional func transitionFromContextProviderTransitionDidEnter(to contextProvider: TransitionToContextProvider)
    @objc optional func transitionFromContextProviderTransitionWillExit(to contextProvider: TransitionToContextProvider)
    @objc optional func transitionFromContextProviderTransitionDidExit(to contextProvider: TransitionToContextProvider)
}
