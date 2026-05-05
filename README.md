# SwiftUI macOS Editor

## 简介

演示一个最小的 SwiftUI macOS 窗口，窗口内容只有一个普通 `TextEditor`。

## 快速开始

```bash
cd swiftui-macos-texteditor-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUITextEditorDemo.app
```

## 概念讲解

### Window

`App` 定义主窗口，直接把 `ContentView` 放进去：

```swift
Window("Editor", id: "main") {
    ContentView()
}
```

### TextEditor

`TextEditor` 绑定一个 `String`，就是最基础的多行文本输入：

```swift
@State private var text = ""

TextEditor(text: $text)
```

## 完整示例

```swift
struct ContentView: View {
    @State private var text = ""

    var body: some View {
        TextEditor(text: $text)
            .padding()
    }
}
```

## 完整讲解（中文）

这个 demo 很单纯：

1. 启动后创建一个标题为 `Editor` 的窗口。
2. 窗口里只放一个 `TextEditor`。
3. `text` 是本地 `@State`，输入什么就显示什么。

这里没有加占位符、工具栏、字符统计、存储、语法高亮。

如果你只想要“一个可输入多行文本的窗口”，这个版本已经是最小实现。
