import AppKit
import SwiftUI
import AppKit

struct ContentView: View {
    @State private var text = Self.demoText

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SwiftUI macOS Editor")
                .font(.title2)
                .foregroundStyle(.black)

            PlainTextEditor(text: $text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .frame(minWidth: 720, minHeight: 480)
        .background(Color(nsColor: EditorTheme.canvasColor))
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
    """
}

private enum EditorTheme {
    static let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let canvasColor = NSColor(calibratedWhite: 0.97, alpha: 1)
    static let editorBackgroundColor = NSColor(calibratedRed: 1, green: 0.97, blue: 0.78, alpha: 1)
    static let textColor = NSColor(calibratedWhite: 0.08, alpha: 1)
    static let selectionColor = NSColor(calibratedRed: 0.99, green: 0.86, blue: 0.45, alpha: 1)

    static var typingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: textColor,
        ]
    }

    static func makeAttributedString(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: typingAttributes)
    }

    static func apply(to textView: NSTextView) {
        textView.appearance = NSAppearance(named: .aqua)
        textView.usesAdaptiveColorMappingForDarkAppearance = false
        textView.drawsBackground = true
        textView.backgroundColor = editorBackgroundColor
        textView.font = font
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.typingAttributes = typingAttributes
        textView.selectedTextAttributes = [
            .backgroundColor: selectionColor,
            .foregroundColor: textColor,
        ]
    }

    static func restyleTextStorage(of textView: NSTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let range = NSRange(location: 0, length: textStorage.length)
        guard range.length > 0 else {
            return
        }

        textStorage.setAttributes(typingAttributes, range: range)
    }
}

private struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .lineBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = EditorTheme.editorBackgroundColor
        scrollView.appearance = NSAppearance(named: .aqua)

        let textView = ThemedTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.textContainer?.lineFragmentPadding = 6
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        EditorTheme.apply(to: textView)
        textView.textStorage?.setAttributedString(EditorTheme.makeAttributedString(text))

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? ThemedTextView else {
            return
        }

        EditorTheme.apply(to: textView)

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(EditorTheme.makeAttributedString(text))
            textView.setSelectedRange(selectedRange)
        } else {
            EditorTheme.restyleTextStorage(of: textView)
        }
    }

    final class ThemedTextView: NSTextView {
        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()
            EditorTheme.apply(to: self)
            EditorTheme.restyleTextStorage(of: self)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor

        init(parent: PlainTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            EditorTheme.apply(to: textView)
            EditorTheme.restyleTextStorage(of: textView)
            parent.text = textView.string
        }
    }
}
