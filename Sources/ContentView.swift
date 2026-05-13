import AppKit
import SwiftUI
import AppKit

struct ContentView: View {
    private let secondaryTextColor = Color(nsColor: NSColor(calibratedWhite: 0.35, alpha: 1))
    @State private var text = Self.demoText
    @State private var snapshot = EditorSnapshot.empty

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SwiftUI Text Area Demo")
                .font(.title2)
                .foregroundStyle(.black)

            GroupBox("编辑区") {
                InstrumentedTextView(text: $text, snapshot: $snapshot)
                    .frame(minHeight: 260)
            }
            .groupBoxStyle(LightPanelGroupBoxStyle())

            GroupBox("实时信息") {
                VStack(alignment: .leading, spacing: 8) {
                    MetricRow(label: "chars", value: "\(snapshot.characterCount)")
                    MetricRow(label: "lines", value: "\(snapshot.lineCount)")
                    MetricRow(label: "font", value: "\(snapshot.fontName) \(snapshot.fontSizeText)")
                    MetricRow(label: "padding", value: "top/bottom \(snapshot.topBottomPaddingText), left/right \(snapshot.leftRightPaddingText)")
                    MetricRow(label: "v-scroll", value: "\(snapshot.hasVerticalScrollerText), need scroll now \(snapshot.needsVerticalScrollText)")
                    MetricRow(label: "viewport", value: "height \(snapshot.viewportHeightText), content \(snapshot.contentHeightText), offsetY \(snapshot.scrollOffsetYText)")
                    MetricRow(label: "visible lines", value: snapshot.visibleLineNumbersText)
                    MetricRow(label: "hidden lines", value: snapshot.hiddenLineNumbersText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .groupBoxStyle(LightPanelGroupBoxStyle())

            GroupBox("当前内容") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(snapshot.lines.enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(snapshot.visibleLineNumberSet.contains(index + 1) ? "visible" : "hidden")
                                    .foregroundStyle(snapshot.visibleLineNumberSet.contains(index + 1) ? Color.green : secondaryTextColor)
                                Text("L\(index + 1)")
                                    .frame(width: 44, alignment: .leading)
                                Text(line.isEmpty ? "''" : line)
                                    .textSelection(.enabled)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 220)
            }
            .groupBoxStyle(LightPanelGroupBoxStyle())
        }
        .padding(16)
        .frame(minWidth: 860, minHeight: 760)
        .background(Color.white)
        .preferredColorScheme(.light)
    }
}

private extension ContentView {
    static let demoText = """
    这是第 1 行。
    这是第 2 行。
    这是第 3 行。
    这是第 4 行。
    这是第 5 行。
    这是第 6 行。
    这是第 7 行。
    这是第 8 行。
    这是第 9 行。
    这是第 10 行。
    这是第 11 行。
    这是第 12 行。
    """
}

private struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(nsColor: NSColor(calibratedWhite: 0.35, alpha: 1)))
                .frame(width: 140, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .textSelection(.enabled)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LightPanelGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
                .font(.headline)
                .foregroundStyle(.black)

            configuration.content
                .foregroundStyle(.black)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct InstrumentedTextView: NSViewRepresentable {
    private static let editorFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    private static let editorTextColor = NSColor.black

    @Binding var text: String
    @Binding var snapshot: EditorSnapshot

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .white
        scrollView.appearance = NSAppearance(named: .aqua)
        scrollView.contentView.postsBoundsChangedNotifications = true

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.appearance = NSAppearance(named: .aqua)
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.drawsBackground = true
        textView.backgroundColor = .white
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.textContainer?.lineFragmentPadding = 6
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        Self.applyEditorStyle(textView, string: text)

        scrollView.documentView = textView
        context.coordinator.connect(scrollView: scrollView, textView: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            Self.applyEditorStyle(textView, string: text)
        } else {
            Self.applyEditorStyle(textView)
        }

        context.coordinator.pushSnapshot()
    }

    private static func applyEditorStyle(_ textView: NSTextView, string: String? = nil) {
        textView.font = editorFont
        textView.textColor = editorTextColor
        textView.insertionPointColor = editorTextColor

        var typingAttributes = textView.typingAttributes
        typingAttributes[.font] = editorFont
        typingAttributes[.foregroundColor] = editorTextColor
        textView.typingAttributes = typingAttributes

        let attrs: [NSAttributedString.Key: Any] = [
            .font: editorFont,
            .foregroundColor: editorTextColor,
        ]

        if let string {
            textView.textStorage?.setAttributedString(NSAttributedString(string: string, attributes: attrs))
        } else {
            let range = NSRange(location: 0, length: textView.string.utf16.count)
            textView.textStorage?.setAttributes(attrs, range: range)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InstrumentedTextView
        private weak var scrollView: NSScrollView?
        private weak var textView: NSTextView?
        private var boundsObserver: NSObjectProtocol?

        init(parent: InstrumentedTextView) {
            self.parent = parent
        }

        deinit {
            if let boundsObserver {
                NotificationCenter.default.removeObserver(boundsObserver)
            }
        }

        func connect(scrollView: NSScrollView, textView: NSTextView) {
            self.scrollView = scrollView
            self.textView = textView

            if let boundsObserver {
                NotificationCenter.default.removeObserver(boundsObserver)
            }

            boundsObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                self?.pushSnapshot()
            }

            pushSnapshot()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else {
                return
            }

            InstrumentedTextView.applyEditorStyle(textView)
            parent.text = textView.string
            pushSnapshot()
        }

        func pushSnapshot() {
            guard let scrollView, let textView else {
                return
            }

            let nextSnapshot = EditorSnapshot.capture(textView: textView, scrollView: scrollView)
            if parent.snapshot != nextSnapshot {
                parent.snapshot = nextSnapshot
            }
        }
    }
}

private struct EditorSnapshot: Equatable {
    var lines: [String]
    var characterCount: Int
    var fontName: String
    var fontSize: CGFloat
    var insetWidth: CGFloat
    var insetHeight: CGFloat
    var lineFragmentPadding: CGFloat
    var hasVerticalScroller: Bool
    var needsVerticalScroll: Bool
    var viewportHeight: CGFloat
    var contentHeight: CGFloat
    var scrollOffsetY: CGFloat
    var visibleLineNumbers: [Int]
    var hiddenLineNumbers: [Int]

    static let empty = EditorSnapshot(
        lines: [""],
        characterCount: 0,
        fontName: "-",
        fontSize: 0,
        insetWidth: 0,
        insetHeight: 0,
        lineFragmentPadding: 0,
        hasVerticalScroller: false,
        needsVerticalScroll: false,
        viewportHeight: 0,
        contentHeight: 0,
        scrollOffsetY: 0,
        visibleLineNumbers: [1],
        hiddenLineNumbers: []
    )

    var lineCount: Int {
        lines.count
    }

    var visibleLineNumberSet: Set<Int> {
        Set(visibleLineNumbers)
    }

    var fontSizeText: String {
        Self.format(fontSize)
    }

    var topBottomPaddingText: String {
        Self.format(insetHeight)
    }

    var leftRightPaddingText: String {
        Self.format(insetWidth + lineFragmentPadding)
    }

    var hasVerticalScrollerText: String {
        hasVerticalScroller ? "yes" : "no"
    }

    var needsVerticalScrollText: String {
        needsVerticalScroll ? "yes" : "no"
    }

    var viewportHeightText: String {
        Self.format(viewportHeight)
    }

    var contentHeightText: String {
        Self.format(contentHeight)
    }

    var scrollOffsetYText: String {
        Self.format(scrollOffsetY)
    }

    var visibleLineNumbersText: String {
        Self.describe(lineNumbers: visibleLineNumbers)
    }

    var hiddenLineNumbersText: String {
        Self.describe(lineNumbers: hiddenLineNumbers)
    }

    static func capture(textView: NSTextView, scrollView: NSScrollView) -> EditorSnapshot {
        let text = textView.string
        let lines = text.components(separatedBy: .newlines)
        let font = textView.font ?? .systemFont(ofSize: NSFont.systemFontSize)
        let inset = textView.textContainerInset
        let lineFragmentPadding = textView.textContainer?.lineFragmentPadding ?? 0
        let viewportHeight = scrollView.contentView.documentVisibleRect.height
        let scrollOffsetY = scrollView.contentView.bounds.origin.y
        let contentHeight = measureContentHeight(textView: textView)
        let visibleLineNumbers = measureVisibleLineNumbers(textView: textView, lines: lines)
        let hiddenLineNumbers = Array(1...max(lines.count, 1)).filter { !Set(visibleLineNumbers).contains($0) }

        return EditorSnapshot(
            lines: lines.isEmpty ? [""] : lines,
            characterCount: text.count,
            fontName: font.fontName,
            fontSize: font.pointSize,
            insetWidth: inset.width,
            insetHeight: inset.height,
            lineFragmentPadding: lineFragmentPadding,
            hasVerticalScroller: scrollView.hasVerticalScroller,
            needsVerticalScroll: contentHeight > viewportHeight + 0.5,
            viewportHeight: viewportHeight,
            contentHeight: contentHeight,
            scrollOffsetY: scrollOffsetY,
            visibleLineNumbers: visibleLineNumbers,
            hiddenLineNumbers: hiddenLineNumbers
        )
    }

    private static func measureContentHeight(textView: NSTextView) -> CGFloat {
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            return textView.bounds.height
        }

        layoutManager.ensureLayout(for: textContainer)
        return layoutManager.usedRect(for: textContainer).height + textView.textContainerInset.height * 2
    }

    private static func measureVisibleLineNumbers(textView: NSTextView, lines: [String]) -> [Int] {
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            return [1]
        }

        layoutManager.ensureLayout(for: textContainer)

        let glyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textContainer)
        if glyphRange.length == 0 {
            return [1]
        }

        let lineStarts = buildLineStarts(lines: lines)
        var visible = Set<Int>()

        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, fragmentGlyphRange, _ in
            let characterRange = layoutManager.characterRange(forGlyphRange: fragmentGlyphRange, actualGlyphRange: nil)
            let lineNumber = lineNumber(forCharacterLocation: characterRange.location, lineStarts: lineStarts)
            visible.insert(lineNumber)
        }

        return visible.isEmpty ? [1] : visible.sorted()
    }

    private static func buildLineStarts(lines: [String]) -> [Int] {
        var starts: [Int] = []
        var offset = 0

        for (index, line) in lines.enumerated() {
            starts.append(offset)
            offset += (line as NSString).length
            if index < lines.count - 1 {
                offset += 1
            }
        }

        return starts.isEmpty ? [0] : starts
    }

    private static func lineNumber(forCharacterLocation location: Int, lineStarts: [Int]) -> Int {
        for index in stride(from: lineStarts.count - 1, through: 0, by: -1) {
            if location >= lineStarts[index] {
                return index + 1
            }
        }

        return 1
    }

    private static func format(_ value: CGFloat) -> String {
        String(format: "%.1f", value)
    }

    private static func describe(lineNumbers: [Int]) -> String {
        if lineNumbers.isEmpty {
            return "-"
        }

        let preview = lineNumbers.prefix(20).map(String.init).joined(separator: ", ")
        if lineNumbers.count <= 20 {
            return preview
        }

        return "\(preview) ... total \(lineNumbers.count)"
    }
}
