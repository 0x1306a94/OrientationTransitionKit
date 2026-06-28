# iOS 16+ 方向监听说明

## 背景

在全屏转场结束时，业务通常需要在正确的界面方向下执行后续逻辑，例如退出横屏后立即 push 竖屏页面。如果过早回调，`UIViewController` 或 `UIWindowScene` 暴露的方向可能仍停留在旧值，导致目标页面进入时再次旋转或布局抖动。

## iOS 16 之前

iOS 16 之前常用 `UIViewController.attemptRotationToDeviceOrientation()` 触发方向更新，并读取 `UIWindowScene.interfaceOrientation` 判断当前方向。这个值基本代表当前 scene 的界面方向，因此可以通过 KVO 观察 `interfaceOrientation`，等它变成预期方向后再触发 `didEnter` 或 `didExit` 回调。

## iOS 16+ 的变化

iOS 16 引入了 scene geometry 更新模型。应用应通过：

```swift
windowScene.requestGeometryUpdate(preferences)
```

请求目标方向。此时 `interfaceOrientation` 的更新时序不再适合作为唯一依据；转场完成回调发生时，UIKit 可能已经结束了动画，但 scene 的有效几何信息还没有同步到预期方向。

因此 iOS 16+ 应优先观察：

```swift
windowScene.effectiveGeometry
```

并从 `effectiveGeometry.interfaceOrientation` 获取当前真实生效的界面方向。

## 当前实现策略

`TransitionCoordinator` 在转场动画完成后不会立即发送最终生命周期回调，而是先检查当前方向：

1. 如果当前方向已经等于预期方向，立即回调。
2. 如果不一致，iOS 16+ 调用 `requestGeometryUpdate`，旧系统调用 `attemptRotationToDeviceOrientation()`。
3. 再次检查方向。
4. 仍不一致时启动 KVO：iOS 16+ 观察 `effectiveGeometry`，旧系统观察 `interfaceOrientation`。
5. 观察到预期方向后，停止 KVO 并发送 `didEnter` 或 `didExit`。

## 为什么不能只依赖 dismiss completion

`dismiss` 的 completion 只表示控制器转场流程结束，不保证 scene 方向已经完成更新。尤其在 iOS 16+，方向请求和 geometry 生效存在异步时序。如果在 completion 中直接 push 竖屏页面，页面可能先按横屏环境进入，再被 UIKit 修正为竖屏，表现为额外旋转一次。

通过 KVO 等待 `effectiveGeometry.interfaceOrientation` 到达预期值，可以把后续业务回调延后到方向稳定之后，避免退出全屏后的二次旋转。
