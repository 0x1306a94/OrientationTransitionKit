import Testing
import UIKit
@testable import OrientationTransitionKit

@MainActor
@Test func coordinatorRequestsPresentAnimatorFromProvider() {
    let provider = SpyTransitionAnimationProvider()
    let fromContextProvider = SpyFromContextProvider()
    let toContextProvider = SpyToContextProvider()
    let coordinator = TransitionCoordinator(
        fromContextProvider: fromContextProvider,
        toContextProvider: toContextProvider,
        fromInterfaceOrientation: .portrait,
        toInterfaceOrientation: .landscapeRight,
        animationProvider: provider
    )

    let animator = coordinator.animationController(
        forPresented: toContextProvider.transitionToContextProviderViewController(),
        presenting: fromContextProvider.transitionFromContextProviderViewController(),
        source: fromContextProvider.transitionFromContextProviderViewController()
    )

    #expect(animator != nil)
}

@MainActor
@Test func coordinatorKeepsInitialContextProvidersAndOrientations() {
    let provider = SpyTransitionAnimationProvider()
    let fromContextProvider = SpyFromContextProvider()
    let toContextProvider = SpyToContextProvider()
    let coordinator = TransitionCoordinator(
        fromContextProvider: fromContextProvider,
        toContextProvider: toContextProvider,
        fromInterfaceOrientation: .portrait,
        toInterfaceOrientation: .landscapeRight,
        animationProvider: provider
    )

    _ = coordinator.animationController(
        forPresented: toContextProvider.transitionToContextProviderViewController(),
        presenting: fromContextProvider.transitionFromContextProviderViewController(),
        source: fromContextProvider.transitionFromContextProviderViewController()
    )

    #expect(coordinator.fromContextProvider === fromContextProvider)
    #expect(coordinator.toContextProvider === toContextProvider)
    #expect(coordinator.fromInterfaceOrientation == .portrait)
    #expect(coordinator.toInterfaceOrientation == .landscapeRight)
}

@MainActor
@Test func defaultTransitionAnimationProviderConformsToAnimationProvider() {
    let provider: TransitionAnimationProvider = DefaultTransitionAnimationProvider()

    #expect(provider is DefaultTransitionAnimationProvider)
}

@MainActor
@Test func defaultTransitionAnimationProviderUsesCustomAnimatorFactory() {
    var factoryCallCount = 0
    let provider = DefaultTransitionAnimationProvider {
        factoryCallCount += 1
        return UIViewPropertyAnimator(duration: 0, curve: .linear)
    }
    let transitionContext = FakeTransitionContext()

    _ = provider.transitionAnimationProviderPresentAnimator(
        fromContextProvider: SpyFromContextProvider(),
        toContextProvider: SpyToContextProvider(),
        fromInterfaceOrientation: .portrait,
        toInterfaceOrientation: .landscapeRight,
        transitionContext: transitionContext
    )

    #expect(factoryCallCount == 1)
}

@MainActor
@Test func dismissAsksToContextProviderToPrepareLandscapeSizedTransitionView() {
    let fromContextProvider = SpyFromContextProvider()
    let toContextProvider = SpyToContextProvider()
    let provider = DefaultTransitionAnimationProvider()
    let transitionContext = FakeTransitionContext()
    let containerView = transitionContext.containerView
    containerView.addSubview(transitionContext.fromView)

    _ = provider.transitionAnimationProviderDismissAnimator(
        fromContextProvider: fromContextProvider,
        toContextProvider: toContextProvider,
        fromInterfaceOrientation: .landscapeRight,
        toInterfaceOrientation: .portrait,
        transitionContext: transitionContext
    )

    #expect(toContextProvider.preparedTransitionViewBoundsSize == CGSize(width: 844, height: 390))
    #expect(fromContextProvider.didFinishTransitionView == false)
}

@MainActor
private final class SpyFromContextProvider: NSObject, TransitionFromContextProvider {
    private let viewController = UIViewController()
    private(set) var preparedTransitionViewBoundsSize: CGSize?
    private(set) var didFinishTransitionView = false

    func transitionFromContextProviderViewController() -> UIViewController {
        viewController
    }

    func transitionFromContextProviderTransitionFrame(in containerView: UIView) -> CGRect {
        CGRect(x: 12, y: 20, width: 320, height: 180)
    }

    func transitionFromContextProviderPrepareTransitionView(_ transitionView: UIView) {
        preparedTransitionViewBoundsSize = transitionView.bounds.size
    }

    func transitionFromContextProviderFinishTransitionView() {
        didFinishTransitionView = true
    }
}

@MainActor
private final class SpyToContextProvider: NSObject, TransitionToContextProvider {
    private let viewController = UIViewController()
    private(set) var preparedTransitionViewBoundsSize: CGSize?
    private(set) var didFinishTransitionView = false

    func transitionToContextProviderViewController() -> UIViewController {
        viewController
    }

    func transitionToContextProviderTransitionFrame(in containerView: UIView) -> CGRect {
        CGRect(x: 0, y: 0, width: 844, height: 390)
    }

    func transitionToContextProviderPrepareTransitionView(_ transitionView: UIView) {
        preparedTransitionViewBoundsSize = transitionView.bounds.size
    }

    func transitionToContextProviderFinishTransitionView() {
        didFinishTransitionView = true
    }
}

@MainActor
private final class FakeTransitionContext: NSObject, UIViewControllerContextTransitioning {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
    let fromView = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
    let toView = UIView(frame: CGRect(x: 0, y: 0, width: 844, height: 390))

    private let fromViewController = UIViewController()
    private let toViewController = UIViewController()

    var isAnimated: Bool { true }
    var isInteractive: Bool { false }
    var transitionWasCancelled: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .fullScreen }
    var targetTransform: CGAffineTransform { .identity }

    func updateInteractiveTransition(_ percentComplete: CGFloat) {}

    func finishInteractiveTransition() {}

    func cancelInteractiveTransition() {}

    func pauseInteractiveTransition() {}

    func completeTransition(_ didComplete: Bool) {}

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        switch key {
        case .from:
            fromViewController.view = fromView
            return fromViewController
        case .to:
            toViewController.view = toView
            return toViewController
        default:
            return nil
        }
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        switch key {
        case .from:
            return fromView
        case .to:
            return toView
        default:
            return nil
        }
    }

    func initialFrame(for viewController: UIViewController) -> CGRect {
        containerView.bounds
    }

    func finalFrame(for viewController: UIViewController) -> CGRect {
        containerView.bounds
    }
}

@MainActor
private final class SpyTransitionAnimationProvider: NSObject, TransitionAnimationProvider {
    func transitionAnimationProviderPresentAnimator(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        UIViewPropertyAnimator(duration: 0, curve: .linear)
    }

    func transitionAnimationProviderDismissAnimator(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        UIViewPropertyAnimator(duration: 0, curve: .linear)
    }
}
