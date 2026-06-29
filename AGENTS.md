# Repository Guidelines

## 项目结构与模块组织

`OrientationTransitionKit` 是仅支持 iOS 的 Swift Package。核心源码位于 `Sources/OrientationTransitionKit/`，每个文件负责一个清晰角色，例如 `TransitionCoordinator.swift`、`TransitionAnimator.swift`、`DefaultTransitionAnimationProvider.swift`。

测试位于 `Tests/OrientationTransitionKitTests/`。示例工程在 `Sample/`：`Sample/Sample/` 是 Swift 示例，`Sample/SampleOC/` 是 Objective-C 示例，`Sample/Configuration/` 存放共享构建配置。资源文件和 `Info.plist` 应保留在所属 sample target 目录内。

## 构建、测试与开发命令

本仓库依赖 UIKit，优先使用 Xcode 的 iOS Simulator 环境验证：

```sh
xcodebuild test -scheme OrientationTransitionKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild -project Sample/Sample.xcodeproj -scheme Sample -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Sample/Sample.xcodeproj -scheme SampleOC -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
```

第一条命令运行 Swift Package 测试。提交前运行 `git diff --check`，检查空白错误和冲突标记。

## 代码风格与命名约定

Swift 使用 4 空格缩进，公开 API 显式标注访问级别，保持一个主要类型对应一个文件。协议方法命名需要语义完整并兼容 Objective-C，例如 `transitionFromContextProviderPrepareTransitionView(_:transitionView:)`。

Objective-C 示例使用 ARC 风格和清晰属性命名。引用 Swift 暴露类型时以生成头为准，例如 `OTKTransitionCoordinator`。

## 测试规范

测试使用 Swift Testing（`import Testing`）。测试名描述行为，例如 `coordinatorKeepsInitialContextProvidersAndOrientations`。修改公开 API、转场生命周期或方向处理时，应补充聚焦测试。涉及可视转场时，还需要构建 Swift 与 Objective-C 两个示例。

## 提交与 PR 规范

近期提交使用简短祈使句，例如 `Add orientation transition kit samples`。每次提交聚焦一个逻辑变更。

PR 应包含变更摘要、已运行的验证命令；如果影响转场视觉效果，附截图或录屏。修改公开 Swift API 时，说明 Objective-C 兼容性影响。

## Agent 注意事项

保持变更小且局限在仓库内。除非确实需要 target membership 或构建配置，不要修改 `Sample/Sample.xcodeproj/project.pbxproj`。新增源码优先放入现有 package 或 sample 目录。
