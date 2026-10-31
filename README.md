# OrientationTransitionKit

English | [简体中文](Docs/README_zh.md)

`OrientationTransitionKit` is an iOS Swift Package for custom orientation transitions between a portrait page and a landscape page. It provides a set of context protocols, a transition coordinator, and a default video-style rotate-and-scale animation, which suits full-screen video players.

## Features

- Rotates and scales from a portrait container into a landscape container, and back on exit.
- The transition content is moved into a temporary transition container by your callbacks, so the same player view can be reused.
- Works from both Swift and Objective-C.
- On iOS 16+, uses `UIWindowScene.effectiveGeometry` to read the actual interface orientation.
- `DefaultTransitionAnimationProvider` accepts a custom `UIViewImplicitlyAnimating`, so the animation curve can be customized.

## Directory Structure

```text
Sources/OrientationTransitionKit/   Library source
Tests/OrientationTransitionKitTests/ Package tests
Sample/Sample/                      Swift sample
Sample/SampleOC/                    Objective-C sample
Docs/                               Design and implementation notes
```

## Basic Usage

Implement the context protocols on both ends of the transition:

```swift
final class HomeViewController: UIViewController, TransitionFromContextProvider {
    func transitionFromContextProviderViewController(_ contextProvider: TransitionFromContextProvider) -> UIViewController { self }
    func transitionFromContextProviderTransitionFrame(_ contextProvider: TransitionFromContextProvider, in containerView: UIView) -> CGRect { .zero }
    func transitionFromContextProviderPrepareTransitionView(_ contextProvider: TransitionFromContextProvider, transitionView: UIView) {}
    func transitionFromContextProviderFinishTransitionView(_ contextProvider: TransitionFromContextProvider) {}
}
```

Create and retain a `TransitionCoordinator`:

```swift
let animationProvider = DefaultTransitionAnimationProvider(duration: 0.25, curve: .easeInOut)
let coordinator = TransitionCoordinator(
    fromContextProvider: portraitProvider,
    toContextProvider: landscapeProvider,
    fromInterfaceOrientation: .portrait,
    toInterfaceOrientation: .landscapeRight,
    animationProvider: animationProvider
)
landscapeViewController.modalPresentationStyle = .fullScreen
landscapeViewController.transitioningDelegate = coordinator
```

Keep a strong reference to the `TransitionCoordinator` until the transition finishes.

The presented view controller must explicitly set `modalPresentationStyle = .fullScreen` (the default `.automatic` does not work). Only `.fullScreen` removes the presenting view and lets the system rotate the interface to the presented view controller's `supportedInterfaceOrientations`. Styles such as `.overFullScreen` and `.custom` keep the presenting orientation and break the transition. Using any other style triggers an assertion in Debug builds.

## iPad and Foldable Devices

On resizable environments such as iPad and the inner display of iPhone Duo, the system ignores the page's `supportedInterfaceOrientations` and the interface always follows the physical device orientation, so it never rotates to landscape. In these environments, go full screen in the current orientation and only scale.

Use `shouldRotateHandler` to decide whether a transition rotates. It is called at the start of every present and dismiss, so folding or unfolding the device while in full screen is handled based on the environment at exit time:

- Return `true`: rotate between `fromInterfaceOrientation` and `toInterfaceOrientation`.
- Return `false`: both ends use the scene's current orientation, no rotation happens, and `DidEnter` / `DidExit` are called as soon as the transition ends.
- When the handler is not set or the window scene is unavailable, the transition rotates.

```swift
coordinator.shouldRotateHandler = { windowScene in
    let traitCollection = windowScene.traitCollection
    // Example: keep the current orientation for regular/regular (iPad, foldable inner display)
    return !(traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular)
}
```

```objc
coordinator.shouldRotateHandler = ^BOOL(UIWindowScene *windowScene) {
    UITraitCollection *traitCollection = windowScene.traitCollection;
    return !(traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular);
};
```

The size class check above is only an example; verify it on your target devices. Without rotation, the full-screen page is shown at any size and orientation, so its layout must adapt.

## Sample Signing Configuration

The sample project provides default signing settings in `Sample/Configuration/Config.xcconfig`, which ends with:

```xcconfig
#include? "Developer.xcconfig"
```

`#include?` is an optional include. The repository keeps shared defaults, and developers can override local signing settings in `Sample/Configuration/Developer.xcconfig`, for example:

```xcconfig
BASE_PRODUCT_BUNDLE_IDENTIFIER = com.example.OrientationTransitionKitSample
DEVELOPMENT_TEAM = YOURTEAMID
CODE_SIGN_IDENTITY = Apple Development
CODE_SIGN_IDENTITY[config=Release] = Apple Distribution
PROVISIONING_PROFILE_SPECIFIER = match Development com.example.*
PROVISIONING_PROFILE_SPECIFIER[config=Release] = match AdHoc com.example.*
```

The Swift sample's bundle id becomes `$(BASE_PRODUCT_BUNDLE_IDENTIFIER).swift` and the Objective-C sample's becomes `$(BASE_PRODUCT_BUNDLE_IDENTIFIER).oc`. For simulator-only builds, you can still pass `CODE_SIGNING_ALLOWED=NO` on the command line.

## Verification Commands

```sh
xcodebuild test -scheme OrientationTransitionKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild -project Sample/Sample.xcodeproj -scheme Sample -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Sample/Sample.xcodeproj -scheme SampleOC -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
```

## More Docs

- [iOS 16+ orientation observation notes](Docs/iOS16OrientationObservation.md)

## Demo Preview
- iOS 15.0
  
https://github.com/user-attachments/assets/8f35c2d7-1be7-4027-b122-14819e9bbd20

- iOS 18.5
  
https://github.com/user-attachments/assets/f09f3883-a496-40f8-9624-686111af55eb

- iOS 26.5.1

https://github.com/user-attachments/assets/5c77585c-c665-4455-96f4-f9c7c3ddd9da
