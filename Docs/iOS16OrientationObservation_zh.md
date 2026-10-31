# iOS 16+ 方向监听说明

[English](iOS16OrientationObservation.md) | 简体中文

## 背景

在全屏转场结束时，业务通常需要在正确的界面方向下执行后续逻辑，例如退出横屏后立即 push 竖屏页面。如果过早回调，`UIViewController` 或 `UIWindowScene` 暴露的方向可能仍停留在旧值，导致目标页面进入时再次旋转或布局抖动。

## iOS 16 之前

iOS 16 之前常用 `UIViewController.attemptRotationToDeviceOrientation()` 触发方向更新，并读取 `UIWindowScene.interfaceOrientation` 判断当前方向。这个值基本代表当前 scene 的界面方向，因此可以通过 KVO 观察 `interfaceOrientation`，等它变成预期方向后再触发 `didEnter` 或 `didExit` 回调。

## iOS 16+ 的变化

iOS 16 引入了 scene geometry 更新模型。转场完成回调发生时，UIKit 可能已经结束了动画，但 scene 的有效几何信息还没有同步到预期方向，`interfaceOrientation` 的更新时序不再适合作为唯一依据。

因此 iOS 16+ 观察：

```swift
windowScene.effectiveGeometry
```

并从 `effectiveGeometry.interfaceOrientation` 获取当前真实生效的界面方向。

方向更新通过 `setNeedsUpdateOfSupportedInterfaceOrientations()` 通知 UIKit 重新读取页面的 `supportedInterfaceOrientations`，不使用 `windowScene.requestGeometryUpdate(_:)`。

## 为什么不使用 requestGeometryUpdate

`requestGeometryUpdate(_:)` 设置的是 scene 级别的几何偏好，转场结束后仍然保留在 scene 上。在折叠设备上，外屏进入并退出全屏后展开到内屏，系统会继续按这个偏好锁定方向，页面无法跟随内屏自动修正。

`.fullScreen` 页面 dismiss 后，UIKit 会按新的顶层页面重新计算支持方向，`setNeedsUpdateOfSupportedInterfaceOrientations()` 已经足够。

## 当前实现策略

`TransitionCoordinator` 在转场动画完成后不会立即发送最终生命周期回调，而是：

1. 每次 present 或 dismiss 开始时，通过 `shouldRotateHandler` 计算本次转场的起止方向。返回 `false` 时两端都使用 scene 当前方向。
2. 起止方向相同（不涉及旋转）时立即回调。
3. 当前方向已经等于预期方向时立即回调。
4. 否则 iOS 16+ 调用 `setNeedsUpdateOfSupportedInterfaceOrientations()`，旧系统调用 `attemptRotationToDeviceOrientation()`，然后再次检查方向。
5. 仍不一致时启动 KVO：iOS 16+ 观察 `effectiveGeometry`，旧系统观察 `interfaceOrientation`。同时启动 0.25s 超时兜底。
6. 观察到预期方向或超时后，停止 KVO、取消兜底，并发送 `didEnter` 或 `didExit`。KVO 命中和超时共用同一个结束路径，保证只回调一次。

## 超时兜底

iPad、iPhone Duo 内屏等可调整尺寸的环境不受页面 `supportedInterfaceOrientations` 约束，系统不会旋转，`effectiveGeometry` 也不会变化，单靠 KVO 会一直等待。超时兜底保证这类环境下转场也能结束。

正常旋转时，`effectiveGeometry.interfaceOrientation` 在系统旋转开始时就会更新，通常远早于 0.25s。在需要兜底的环境下，更推荐通过 `shouldRotateHandler` 返回 `false` 直接跳过等待。

## 为什么不能只依赖 dismiss completion

`dismiss` 的 completion 只表示控制器转场流程结束，不保证 scene 方向已经完成更新。尤其在 iOS 16+，方向更新和 geometry 生效存在异步时序。如果在 completion 中直接 push 竖屏页面，页面可能先按横屏环境进入，再被 UIKit 修正为竖屏，表现为额外旋转一次。

通过 KVO 等待 `effectiveGeometry.interfaceOrientation` 到达预期值，可以把后续业务回调延后到方向稳定之后，避免退出全屏后的二次旋转。
