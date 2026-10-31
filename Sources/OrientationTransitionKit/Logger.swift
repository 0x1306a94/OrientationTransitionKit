import OSLog
import UIKit

extension Logger {
    private static let subsystem = "OrientationTransitionKit"

    static let transitionCoordinator = Logger(subsystem: subsystem, category: "TransitionCoordinator")
    static let transitionAnimator = Logger(subsystem: subsystem, category: "TransitionAnimator")
}

extension UIInterfaceOrientation {
    var logDescription: String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown(\(rawValue))"
        }
    }
}

extension UIViewAnimatingPosition {
    var logDescription: String {
        switch self {
        case .end:
            return "end"
        case .start:
            return "start"
        case .current:
            return "current"
        @unknown default:
            return "unknown(\(rawValue))"
        }
    }
}
