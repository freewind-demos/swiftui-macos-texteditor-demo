import SwiftUI
import AppKit

struct ContentView: View {
    @State private var text = """
第一行
第二行会随内容继续增长，不会出现内部滚动条。
"""
    @State private var editorHeight: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            // 预留外层 padding 后，把稳定可用宽度传给 NSTextView 做真实换行测量。
            let editorWidth = max(proxy.size.width - 48, 200)

            VStack(alignment: .leading, spacing: 12) {
                Text("Auto-growing text area")
                    .font(.title2)

                Text("高度只跟内容走；不留多余空行；不裁剪；不出内部滚动。")
                    .foregroundStyle(.secondary)

                AutoGrowingTextArea(
                    text: $text,
                    height: $editorHeight,
                    width: editorWidth
                )
                .frame(height: editorHeight)
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )

                Text("内容高度: \(Int(editorHeight))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// SwiftUI 自带 TextEditor 在 macOS 上不方便精确控制内容高度，这里桥接到底层 AppKit。
struct AutoGrowingTextArea: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let width: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $height)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.string = text

        if let textContainer = textView.textContainer {
            // 宽度固定、高度放开，layoutManager 才会按目标宽度算出真实多行高度。
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
            textContainer.containerSize = NSSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textContainer.lineFragmentPadding = 0
        }

        textView.textContainerInset = .zero
        scrollView.documentView = textView

        context.coordinator.recalculateHeight(for: textView, width: width)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }

        context.coordinator.recalculateHeight(for: textView, width: width)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var text: Binding<String>
        private var height: Binding<CGFloat>

        init(text: Binding<String>, height: Binding<CGFloat>) {
            self.text = text
            self.height = height
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            if text.wrappedValue != textView.string {
                text.wrappedValue = textView.string
            }

            recalculateHeight(for: textView, width: textView.bounds.width)
        }

        func recalculateHeight(for textView: NSTextView, width: CGFloat) {
            guard width > 0,
                  let textContainer = textView.textContainer,
                  let layoutManager = textView.layoutManager else {
                return
            }

            textContainer.containerSize = NSSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            )

            layoutManager.ensureLayout(for: textContainer)

            // 空内容时 usedRect 可能接近 0，用单行高度兜底，避免组件塌陷。
            let usedHeight = ceil(layoutManager.usedRect(for: textContainer).height)
            let font = textView.font ?? .systemFont(ofSize: NSFont.systemFontSize)
            let lineHeight = ceil(layoutManager.defaultLineHeight(for: font))
            let nextHeight = max(lineHeight, usedHeight)

            textView.frame.size = NSSize(width: width, height: nextHeight)

            guard abs(height.wrappedValue - nextHeight) > 0.5 else {
                return
            }

            // 异步回写，避开 AppKit layout 周期内直接改 SwiftUI state 的更新警告。
            DispatchQueue.main.async {
                self.height.wrappedValue = nextHeight
            }
        }
    }
}
