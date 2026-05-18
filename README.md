# SwiftUI macOS TextEditor Demo

最小 macOS 文本编辑 demo。

## 实际内容

- SwiftUI app
- 单窗口，默认 `800x600`
- 页面只有一个铺满窗口的原生 `TextEditor`
- 文本状态仅存在 `ContentView` 的本地 `@State`
- 无文件读写、无自定义 `NSTextView bridge`、无主题层

## 代码结构

- `Sources/AppMain.swift`
  - app 入口
  - 创建 `ContentView`
  - 设置默认窗口尺寸
- `Sources/ContentView.swift`
  - 持有 `text` 状态
  - 渲染全尺寸 `TextEditor`
- `project.yml`
  - `XcodeGen` 工程定义
  - app 名 `SwiftUITextEditorDemo`
  - macOS target `14.0`
- `scripts/build.sh`
  - 生成 `.xcodeproj`
  - 执行 Debug/Release 构建

## 运行要求

- Xcode
- `XcodeGen`

安装 `XcodeGen`:

```bash
brew install xcodegen
```

## 构建

Debug:

```bash
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUITextEditorDemo.app
```

Release:

```bash
./scripts/build-release.sh
open dist/SwiftUITextEditorDemo.app
```

## 工程生成

项目工程文件来自 `project.yml`，构建脚本会先执行：

```bash
xcodegen generate
```

也可手动生成：

```bash
xcodegen generate
open SwiftUITextEditorDemo.xcodeproj
```

## 当前定位

此仓库是最小基线 demo，适合继续加：

- 文本持久化
- 打开/保存文件
- 编辑器主题
- `NSTextView` 深度定制
