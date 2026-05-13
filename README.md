# SwiftUI macOS Editor

最小可读版 macOS 文本编辑 demo。

## 目标

- 白底深字，系统深浅色切换下仍可读
- 不依赖多层补丁式配色修复
- `View` / `theme` / `NSTextView bridge` 职责分开

## 结构

- `Sources/AppMain.swift`
  - app 入口，窗口固定浅色
- `Sources/ContentView.swift`
  - `ContentView`：页面布局
  - `EditorTheme`：唯一配色与字体来源
  - `PlainTextEditor`：SwiftUI 到 `NSTextView` 的最小桥接

## 为什么不用原生 `TextEditor`

这个 demo 要稳定控制 macOS 编辑区的：

- 当前文本 attrs
- 新输入 `typingAttributes`
- 插入光标颜色
- 背景色
- appearance 变化后的重新应用

原生 `TextEditor` 对这些控制不够直接，所以这里直接桥接 `NSTextView`，把颜色源收口到一处。

## 构建

```bash
cd swiftui-macos-texteditor-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUITextEditorDemo.app
```
