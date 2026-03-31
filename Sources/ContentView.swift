import SwiftUI

struct ContentView: View {
    @State private var text = "这是多行文本编辑器。\n\n你可以在这里输入多行文字。\n\n支持换行！"

    var body: some View {
        VStack(spacing: 20) {
            Text("TextEditor 示例")
                .font(.headline)

            // 基础 TextEditor
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 150)
                .border(Color.gray, width: 1)

            Text("字符数: \(text.count)")
                .foregroundColor(.secondary)

            Divider()

            // 带占位符的 TextEditor
            PlaceholderTextEditor(
                placeholder: "在这里输入笔记...",
                text: $text
            )
            .frame(minHeight: 100)
            .border(Color.blue, width: 1)
        }
        .padding()
    }
}

// 自定义带占位符的 TextEditor
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
