import SwiftUI

@main
struct TextEditorApp: App {
    var body: some Scene {
        Window("Editor", id: "main") {
            ContentView()
        }
        .defaultSize(width: 860, height: 760)
    }
}
