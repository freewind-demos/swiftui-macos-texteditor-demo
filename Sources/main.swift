import Cocoa

@main
struct TextEditorApp: App {
    var body: some Scene {
        Window("TextEditor 多行文本编辑", id: "main") {
            ContentView()
        }
        .defaultSize(width: 500, height: 400)
    }
}
