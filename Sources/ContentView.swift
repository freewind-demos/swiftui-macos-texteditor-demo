import SwiftUI
import AppKit

struct TextLayoutMetrics: Equatable {
    let lineCount: Int
    let singleLineHeight: CGFloat

    var contentHeight: CGFloat {
        CGFloat(lineCount) * singleLineHeight
    }

    static func initial(font: NSFont) -> TextLayoutMetrics {
        let lineHeight = ceil(NSLayoutManager().defaultLineHeight(for: font))
        return TextLayoutMetrics(lineCount: 1, singleLineHeight: lineHeight)
    }
}

struct ContentView: View {
    // `@State` = 这个 View 自己持有的状态。这里存“文本内容”。
    @State private var text = """
第一行
第二行会随内容继续增长，不会出现内部滚动条。
"""
    // 这里不再直接存最终高度，只存“排版指标”：
    // 1. 视觉行数
    // 2. 单行高度
    // 真正高度由当前 View 自己决定怎么算。
    @State private var editorMetrics = TextLayoutMetrics.initial(
        font: .systemFont(ofSize: NSFont.systemFontSize)
    )

    var body: some View {
        GeometryReader { proxy in
            // 预留外层 padding 后，把稳定可用宽度传给 NSTextView 做真实换行测量。
            let editorWidth = max(proxy.size.width - 48, 200)
            let editorHeight = editorMetrics.contentHeight

            VStack(alignment: .leading, spacing: 12) {
                Text("Auto-growing text area")
                    .font(.title2)

                Text("高度只跟内容走；不留多余空行；不裁剪；不出内部滚动。")
                    .foregroundStyle(.secondary)

                AutoGrowingTextArea(
                    // `$text` / `$editorMetrics` 不是值本身，是“可读可写入口”。
                    // 子 View 可经它回写父 View 的状态。
                    text: $text,
                    metrics: $editorMetrics,
                    width: editorWidth
                )
                // 关键：SwiftUI 最终仍要一个 frame 高度。
                // 但这个高度现在由父层自己根据 metrics 算，不再由底层直接塞一个 CGFloat 回来。
                .frame(height: editorHeight)
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )

                Text("视觉行数: \(editorMetrics.lineCount) · 单行高: \(Int(editorMetrics.singleLineHeight))pt · 内容高度: \(Int(editorHeight))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// SwiftUI 自带 TextEditor 在 macOS 上不方便精确控制内容高度。
// 所以这里包一层 AppKit 的 NSTextView，自行拿到底层 layout 结果。
struct AutoGrowingTextArea: NSViewRepresentable {
    // 父 View 传进来的“文本状态入口”。
    // 读它可拿到最新文本，写它可把新文本回传给父 View。
    @Binding var text: String
    // 父 View 传进来的“排版指标入口”。
    // 这里算出行数与单行高后，会写回它；父 View 再自行决定最终高度公式。
    @Binding var metrics: TextLayoutMetrics
    // 外层算好的可用宽度。高度测量必须依赖宽度，因为换行会影响总高度。
    let width: CGFloat

    // 把“文本 + 宽度 -> 视觉行数 + 单行高”的复杂细节收口到一个地方。
    // 外面调用时，不必再直接面对 layoutManager / textContainer 这些对象。
    private static func measureTextLayoutMetrics(text: String, width: CGFloat, font: NSFont) -> TextLayoutMetrics {
        let textStorage = NSTextStorage(string: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(
            containerSize: NSSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        textContainer.lineFragmentPadding = 0

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        layoutManager.ensureLayout(for: textContainer)

        let lineHeight = ceil(layoutManager.defaultLineHeight(for: font))
        var lineCount = 0
        let glyphRange = layoutManager.glyphRange(for: textContainer)

        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, _, _ in
            lineCount += 1
        }

        // 文本以换行结尾时，AppKit 会额外留一条空白行，要把它也算进去。
        if layoutManager.extraLineFragmentTextContainer != nil,
           !layoutManager.extraLineFragmentRect.isEmpty {
            lineCount += 1
        }

        return TextLayoutMetrics(
            lineCount: max(1, lineCount),
            singleLineHeight: lineHeight
        )
    }

    func makeCoordinator() -> Coordinator {
        // Coordinator 是 AppKit delegate 的承接层。
        // SwiftUI struct 本身很轻，不适合直接挂 NSTextViewDelegate。
        Coordinator(text: $text, metrics: $metrics)
    }

    func makeNSView(context: Context) -> NSScrollView {
        // NSScrollView 只是外壳。真正可编辑的是里面的 NSTextView。
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView(frame: .zero)
        // 用户一改字，AppKit 会回调到 Coordinator.textDidChange。
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
        // 首次创建原生控件时，把 SwiftUI 里的文本塞进去。
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

        // 第一次显示前先测一次高度，避免初始 frame 不准。
        context.coordinator.recalculateLayoutMetrics(for: textView, width: width)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // SwiftUI 状态变化后，会反过来走到这里，同步到底层 AppKit 控件。
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            // 如果父 View 的 `text` 已变，推回 NSTextView。
            textView.string = text
        }

        // 宽度可能变了，比如窗口拉伸。
        // 同一段文本在不同宽度下换行数不同，所以要重算高度。
        context.coordinator.recalculateLayoutMetrics(for: textView, width: width)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        // 保存的是 Binding，不是普通值。
        // 所以这里能直接改到父 View 的 `text` / `editorMetrics`。
        private var text: Binding<String>
        private var metrics: Binding<TextLayoutMetrics>

        init(text: Binding<String>, metrics: Binding<TextLayoutMetrics>) {
            self.text = text
            self.metrics = metrics
        }

        func textDidChange(_ notification: Notification) {
            // 这是“用户在 NSTextView 里敲字后”的入口。
            guard let textView = notification.object as? NSTextView else {
                return
            }

            if text.wrappedValue != textView.string {
                // 第 1 步：把原生控件里的最新文本，写回 SwiftUI 状态 `text`。
                text.wrappedValue = textView.string
            }

            // 第 2 步：文本已变，行数可能变，马上重算高度。
            recalculateLayoutMetrics(for: textView, width: textView.bounds.width)
        }

        func recalculateLayoutMetrics(for textView: NSTextView, width: CGFloat) {
            // 这里是“排版指标计算核心”。
            // 输入：当前文本 + 当前宽度。
            // 输出：nextMetrics，并在最后写回 `metrics` Binding。
            guard width > 0 else {
                return
            }

            let font = textView.font ?? .systemFont(ofSize: NSFont.systemFontSize)
            // 现在外层只看得见一个简单规则：
            // “给我文本和宽度，我返回视觉行数与单行高”。
            let nextMetrics = AutoGrowingTextArea.measureTextLayoutMetrics(
                text: textView.string,
                width: width,
                font: font
            )

            // 底层 NSTextView 仍要拿一个真实高度，不然文档视图不会跟着长高。
            textView.frame.size = NSSize(width: width, height: nextMetrics.contentHeight)

            guard metrics.wrappedValue != nextMetrics else {
                return
            }

            // 异步回写，避开 AppKit layout 周期内直接改 SwiftUI state 的更新警告。
            DispatchQueue.main.async {
                // 关键回写点：
                // 1. 把算出的 `lineCount + singleLineHeight` 写进父 View 的 `editorMetrics`
                // 2. SwiftUI 发现状态变了
                // 3. 父 View 自己算 `editorHeight`
                // 4. `AutoGrowingTextArea(...).frame(height: editorHeight)` 重新执行
                // 5. 组件视觉高度随之更新
                self.metrics.wrappedValue = nextMetrics
            }
        }
    }
}
