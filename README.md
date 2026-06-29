# OrientationTransitionKit

`OrientationTransitionKit` 是一个 iOS Swift Package，用于实现竖屏页面与横屏页面之间的自定义方向转场。它提供一组上下文协议、转场协调器和默认视频式旋转放大/缩小动画，适合播放器全屏场景。

## 特性

- 支持从竖屏容器旋转放大进入横屏容器，并反向退出。
- 转场内容由业务方在回调中移动到临时转场容器，适合复用同一个播放器 view。
- 支持 Swift 与 Objective-C 调用。
- iOS 16+ 使用 `UIWindowScene.effectiveGeometry` 判断实际界面方向。
- `DefaultTransitionAnimationProvider` 支持自定义 `UIViewImplicitlyAnimating`，可定制动画曲线。

## 目录结构

```text
Sources/OrientationTransitionKit/   核心库源码
Tests/OrientationTransitionKitTests/ 包测试
Sample/Sample/                      Swift 示例
Sample/SampleOC/                    Objective-C 示例
Docs/                               设计与实现说明
```

## 基本用法

实现转场两端的上下文协议：

```swift
final class HomeViewController: UIViewController, TransitionFromContextProvider {
    func transitionFromContextProviderViewController(_ contextProvider: TransitionFromContextProvider) -> UIViewController { self }
    func transitionFromContextProviderTransitionFrame(_ contextProvider: TransitionFromContextProvider, in containerView: UIView) -> CGRect { .zero }
    func transitionFromContextProviderPrepareTransitionView(_ contextProvider: TransitionFromContextProvider, transitionView: UIView) {}
    func transitionFromContextProviderFinishTransitionView(_ contextProvider: TransitionFromContextProvider) {}
}
```

创建并持有 `TransitionCoordinator`：

```swift
let animationProvider = DefaultTransitionAnimationProvider(duration: 0.25, curve: .easeInOut)
let coordinator = TransitionCoordinator(
    fromContextProvider: portraitProvider,
    toContextProvider: landscapeProvider,
    fromInterfaceOrientation: .portrait,
    toInterfaceOrientation: .landscapeRight,
    animationProvider: animationProvider
)
landscapeViewController.transitioningDelegate = coordinator
```

`TransitionCoordinator` 需要被强持有，直到转场结束。

## 示例工程签名配置

示例工程通过 `Sample/Configuration/Config.xcconfig` 提供默认签名配置，并在末尾使用：

```xcconfig
#include? "Developer.xcconfig"
```

`#include?` 表示可选包含。仓库可以保留一份通用默认值，开发者可在 `Sample/Configuration/Developer.xcconfig` 中覆盖本机签名信息，例如：

```xcconfig
BASE_PRODUCT_BUNDLE_IDENTIFIER = com.example.OrientationTransitionKitSample
DEVELOPMENT_TEAM = YOURTEAMID
CODE_SIGN_IDENTITY = Apple Development
CODE_SIGN_IDENTITY[config=Release] = Apple Distribution
PROVISIONING_PROFILE_SPECIFIER = match Development com.example.*
PROVISIONING_PROFILE_SPECIFIER[config=Release] = match AdHoc com.example.*
```

Swift 示例的 bundle id 会拼接为 `$(BASE_PRODUCT_BUNDLE_IDENTIFIER).swift`，Objective-C 示例会拼接为 `$(BASE_PRODUCT_BUNDLE_IDENTIFIER).oc`。如果只做模拟器构建，也可以继续在命令中传入 `CODE_SIGNING_ALLOWED=NO`。

## 验证命令

```sh
xcodebuild test -scheme OrientationTransitionKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild -project Sample/Sample.xcodeproj -scheme Sample -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Sample/Sample.xcodeproj -scheme SampleOC -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
```

## 更多文档

- [iOS 16+ 方向监听说明](Docs/iOS16OrientationObservation.md)

## Demo Preview
- iOS 15.0
  
https://github.com/user-attachments/assets/8f35c2d7-1be7-4027-b122-14819e9bbd20

- iOS 18.5
  
https://github.com/user-attachments/assets/f09f3883-a496-40f8-9624-686111af55eb

- iOS 26.5.1

https://github.com/user-attachments/assets/5c77585c-c665-4455-96f4-f9c7c3ddd9da

