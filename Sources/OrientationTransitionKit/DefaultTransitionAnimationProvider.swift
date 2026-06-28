import UIKit

@MainActor
@objc(OTKDefaultTransitionAnimationProvider)
@objcMembers
public final class DefaultTransitionAnimationProvider: NSObject, TransitionAnimationProvider {
    public typealias AnimatorFactory = @MainActor () -> UIViewImplicitlyAnimating

    private let animatorFactory: AnimatorFactory

    public init(animatorFactory: @escaping AnimatorFactory) {
        self.animatorFactory = animatorFactory
        super.init()
    }

    public init(duration: TimeInterval = 0.25, curve: UIView.AnimationCurve = .easeInOut) {
        self.animatorFactory = {
            UIViewPropertyAnimator(duration: duration, curve: curve)
        }
        super.init()
    }

    public init(duration: TimeInterval) {
        self.animatorFactory = {
            UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
        }
        super.init()
    }

    public func transitionAnimationProviderPresentAnimator(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        guard
            let toView = transitionContext.view(forKey: .to),
            let toViewController = transitionContext.viewController(forKey: .to)
        else {
            return emptyAnimator()
        }

        let containerView = transitionContext.containerView
        toView.frame = transitionContext.finalFrame(for: toViewController)
        if toView.superview !== containerView {
            containerView.addSubview(toView)
        }
        toView.layoutIfNeeded()

        let startFrame = fromContextProvider.transitionFromContextProviderTransitionFrame(in: containerView)
        let targetFrame = toContextProvider.transitionToContextProviderTransitionFrame(in: containerView)
        let transitionContainerView = transitionContainerView(frame: startFrame)
        let rotationAngle = rotationAngle(
            from: fromInterfaceOrientation,
            to: toInterfaceOrientation
        )

        toView.alpha = 0.01
        containerView.addSubview(transitionContainerView)
        fromContextProvider.transitionFromContextProviderPrepareTransitionView(transitionContainerView)
        transitionContainerView.setNeedsLayout()
        transitionContainerView.layoutIfNeeded()

        let animator = makeAnimator {
            toView.alpha = 1
            self.apply(targetFrame, to: transitionContainerView, rotationAngle: rotationAngle)
        }
        animator.addCompletion? { _ in
            toContextProvider.transitionToContextProviderFinishTransitionView()
            toView.alpha = 1
            transitionContainerView.removeFromSuperview()
        }
        return animator
    }

    public func transitionAnimationProviderDismissAnimator(
        fromContextProvider: TransitionFromContextProvider,
        toContextProvider: TransitionToContextProvider,
        fromInterfaceOrientation: UIInterfaceOrientation,
        toInterfaceOrientation: UIInterfaceOrientation,
        transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        guard
            let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to),
            let toViewController = transitionContext.viewController(forKey: .to)
        else {
            return emptyAnimator()
        }

        let containerView = transitionContext.containerView
        toView.frame = transitionContext.finalFrame(for: toViewController)
        containerView.insertSubview(toView, belowSubview: fromView)
        toView.layoutIfNeeded()
        fromView.layoutIfNeeded()

        let startFrame = toContextProvider.transitionToContextProviderTransitionFrame(in: containerView)
        let targetFrame = fromContextProvider.transitionFromContextProviderTransitionFrame(in: containerView)
        let transitionContainerView = transitionContainerView(frame: startFrame)
        let rotationAngle = rotationAngle(
            from: fromInterfaceOrientation,
            to: toInterfaceOrientation
        )

        containerView.addSubview(transitionContainerView)
        toContextProvider.transitionToContextProviderPrepareTransitionView(transitionContainerView)
        apply(startFrame, to: transitionContainerView, rotationAngle: rotationAngle)

        let animator = makeAnimator {
            fromView.alpha = 0
            self.apply(targetFrame, to: transitionContainerView, rotationAngle: 0)
        }
        animator.addCompletion? { _ in
            fromContextProvider.transitionFromContextProviderFinishTransitionView()
            fromView.alpha = 1
            transitionContainerView.removeFromSuperview()
        }
        return animator
    }

    private func emptyAnimator() -> UIViewImplicitlyAnimating {
        UIViewPropertyAnimator(duration: 0, curve: .linear)
    }

    private func makeAnimator(animations: @escaping () -> Void) -> UIViewImplicitlyAnimating {
        let animator = animatorFactory()
        animator.addAnimations?(animations)
        return animator
    }

    private func transitionContainerView(frame: CGRect) -> UIView {
        let transitionContainerView = UIView(frame: frame)
        transitionContainerView.clipsToBounds = true
        return transitionContainerView
    }

    private func apply(
        _ frame: CGRect,
        to transitionContainerView: UIView,
        rotationAngle: CGFloat
    ) {
        let boundsSize = if rotationAngle == 0 {
            frame.size
        } else {
            CGSize(width: frame.height, height: frame.width)
        }

        transitionContainerView.bounds = CGRect(origin: .zero, size: boundsSize)
        transitionContainerView.center = CGPoint(x: frame.midX, y: frame.midY)
        transitionContainerView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        transitionContainerView.setNeedsLayout()
        transitionContainerView.layoutIfNeeded()
    }

    private func rotationAngle(
        from fromInterfaceOrientation: UIInterfaceOrientation,
        to toInterfaceOrientation: UIInterfaceOrientation
    ) -> CGFloat {
        normalizedRotationAngle(
            angle(for: toInterfaceOrientation) - angle(for: fromInterfaceOrientation)
        )
    }

    private func normalizedRotationAngle(_ rotationAngle: CGFloat) -> CGFloat {
        if rotationAngle > .pi {
            return rotationAngle - 2 * .pi
        }
        if rotationAngle < -.pi {
            return rotationAngle + 2 * .pi
        }
        return rotationAngle
    }

    private func angle(for interfaceOrientation: UIInterfaceOrientation) -> CGFloat {
        switch interfaceOrientation {
        case .portrait:
            return 0
        case .landscapeRight:
            return .pi / 2
        case .landscapeLeft:
            return -.pi / 2
        case .portraitUpsideDown:
            return .pi
        case .unknown:
            return 0
        @unknown default:
            return 0
        }
    }
}
