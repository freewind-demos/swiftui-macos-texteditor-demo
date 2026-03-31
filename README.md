# SwiftUI macOS TextEditor 多行文本编辑

## 简介

演示 SwiftUI 中 TextEditor 的用法，用于多行文本输入和编辑。

## 快速开始

```bash
cd swiftui-macos-texteditor-demo
xcodegen generate
open SwiftUITextEditorDemo.xcodeproj
# Cmd+R 运行
```

## 概念讲解

### 基础 TextEditor

TextEditor 用于多行文本编辑，与 TextField 不同，它支持多行输入：

```swift
@State private var text = ""

TextEditor(text: $text)
    .frame(minHeight: 150)
```

### 固定高度

使用 `.frame()` 设置尺寸：

```swift
TextEditor(text: $text)
    .frame(height: 200)
```

### 带占位符的 TextEditor

TextEditor 原生不支持占位符，需要自定义实现：

```swift
struct PlaceholderTextEditor: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
        }
    }
}
```

### 隐藏背景

macOS 的 TextEditor 默认有背景，使用 `.scrollContentBackground(.hidden)` 可以隐藏：

```swift
TextEditor(text: $text)
    .scrollContentBackground(.hidden)
```

## 完整示例

```swift
struct ContentView: View {
    @State private var text = "初始文本"

    var body: some View {
        VStack {
            TextEditor(text: $text)
                .frame(minHeight: 150)
                .border(Color.gray)

            Text("字符数: \(text.count)")
        }
        .padding()
    }
}
```

## 完整讲解（中文）

### TextEditor vs TextField

| 特性 | TextField | TextEditor |
|------|----------|------------|
| 单行 | 是 | 否 |
| 多行 | 否 | 是 |
| 预设样式 | 占位符 | 需要自定义 |

### 使用场景

- TextField：用户名、邮箱、搜索框等单行输入
- TextEditor：备注、笔记、评论等多行输入

### 性能注意

TextEditor 基于 NSTextView，大量文本时可能有性能考虑。
