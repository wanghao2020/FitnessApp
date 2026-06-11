# iOS Launch Screen 缩放修复设计

## 目标

修复 iOS 模拟器默认启动时 app 内容被兼容缩放、上下出现黑边的问题，让 Fitness RPG 在现代 iPhone 屏幕上以全屏尺寸启动。

## 根因证据

- iOS target 使用 `GENERATE_INFOPLIST_FILE = YES`，构建产物 `Info.plist` 没有 `UILaunchStoryboardName` 或其他 launch screen key。
- 项目内没有 `LaunchScreen.storyboard` 或等价资源。
- 当前截图中 app 以圆角兼容窗口显示在黑色背景中，符合缺少现代 launch screen 配置时的缩放症状。

## 方案

新增最小 `LaunchScreen.storyboard`，并把它加入 iOS target 的 Resources build phase。Debug 和 Release 生成式 plist 均声明：

```text
INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
```

Launch Screen 只负责提供现代屏幕尺寸声明和中性启动背景，不承载产品信息、RPG 装饰、动态内容或业务状态。

## 非目标

- 不修改 Today 页面布局。
- 不新增 app icon、accent color 或资产目录。
- 不修改 watchOS target 的启动界面。
- 不改变 HealthKit、WatchConnectivity、持久化或训练结算逻辑。

## 验证

- 改动前：构建产物 `Info.plist` 提取 `UILaunchStoryboardName` 失败。
- 改动后：iOS build 通过，`UILaunchStoryboardName` 为 `LaunchScreen`。
- 安装并启动 iOS simulator，截图确认 app 内容占满现代 iPhone 屏幕，不再出现兼容缩放黑边。
