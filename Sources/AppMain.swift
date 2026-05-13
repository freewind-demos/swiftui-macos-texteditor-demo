import SwiftUI

@main
struct TextEditorApp: App {
    var body: some Scene {
        Window("Editor", id: "main") {
            ContentView()
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 860, height: 760)
    }
}
