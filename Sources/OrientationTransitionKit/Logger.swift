import OSLog
import UIKit

extension Logger {
    private static let subsystem = "OrientationTransitionKit"

    static let transitionCoordinator = Logger(subsystem: subsystem, category: "TransitionCoordinator")
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
