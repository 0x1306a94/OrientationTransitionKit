# iOS 16+ Orientation Observation

English | [简体中文](iOS16OrientationObservation_zh.md)

## Background

When a full-screen transition ends, your code usually needs to continue in the correct interface orientation, for example pushing a portrait page right after leaving landscape. If the callback fires too early, the orientation reported by `UIViewController` or `UIWindowScene` may still be the old value, and the next page rotates again or its layout jitters on entry.

## Before iOS 16

Before iOS 16, the common approach is to call `UIViewController.attemptRotationToDeviceOrientation()` to trigger an orientation update and read `UIWindowScene.interfaceOrientation` for the current orientation. That value reflects the scene's interface orientation, so you can observe `interfaceOrientation` with KVO and fire `didEnter` or `didExit` once it reaches the expected orientation.

## Changes in iOS 16+

iOS 16 introduced the scene geometry update model. When the transition completion fires, UIKit may have finished the animation while the scene's effective geometry has not yet reached the expected orientation, so the timing of `interfaceOrientation` is no longer reliable on its own.

On iOS 16+ the coordinator observes:

```swift
windowScene.effectiveGeometry
```

and reads the orientation actually in effect from `effectiveGeometry.interfaceOrientation`.

The orientation update is requested with `setNeedsUpdateOfSupportedInterfaceOrientations()`, which tells UIKit to re-read the pages' `supportedInterfaceOrientations`. `windowScene.requestGeometryUpdate(_:)` is not used.

## Why Not requestGeometryUpdate

`requestGeometryUpdate(_:)` sets a scene-level geometry preference that stays on the scene after the transition. On foldable devices, after entering and leaving full screen on the outer display and then unfolding to the inner display, the system keeps locking the orientation to that preference and the page cannot follow the inner display.

After a `.fullScreen` page is dismissed, UIKit recomputes the supported orientations from the new top page, so `setNeedsUpdateOfSupportedInterfaceOrientations()` is enough.

## Current Strategy

`TransitionCoordinator` does not send the final lifecycle callback right after the transition animation. Instead it:

1. At the start of every present or dismiss, resolves the start and end orientations through `shouldRotateHandler`. When it returns `false`, both ends use the scene's current orientation.
2. Calls back immediately when the start and end orientations match (no rotation involved).
3. Calls back immediately when the current orientation already matches the expected one.
4. Otherwise calls `setNeedsUpdateOfSupportedInterfaceOrientations()` on iOS 16+ or `attemptRotationToDeviceOrientation()` on older systems, then checks again.
5. If the orientation still differs, starts KVO: `effectiveGeometry` on iOS 16+, `interfaceOrientation` on older systems. A 0.25s timeout fallback starts at the same time.
6. When the expected orientation is observed or the timeout fires, stops KVO, cancels the fallback, and sends `didEnter` or `didExit`. Both paths share one finish path, so the callback fires only once.

## Timeout Fallback

On resizable environments such as iPad and the iPhone Duo inner display, the system ignores the page's `supportedInterfaceOrientations` and never rotates, so `effectiveGeometry` does not change and KVO alone would wait forever. The timeout fallback makes sure the transition still finishes there.

During a normal rotation, `effectiveGeometry.interfaceOrientation` updates when the system rotation starts, usually well before 0.25s. In environments that need the fallback, prefer returning `false` from `shouldRotateHandler` to skip the wait entirely.

## Why the dismiss Completion Is Not Enough

The `dismiss` completion only means the view controller transition finished; it does not guarantee the scene orientation has been updated. On iOS 16+ in particular, orientation updates and geometry changes are asynchronous. If you push a portrait page directly in the completion, it may first appear in a landscape environment and then be corrected to portrait by UIKit, which shows up as an extra rotation.

Waiting with KVO until `effectiveGeometry.interfaceOrientation` reaches the expected value delays the follow-up callback until the orientation is stable and avoids the extra rotation after leaving full screen.
