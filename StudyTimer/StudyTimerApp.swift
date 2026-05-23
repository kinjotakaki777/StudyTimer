import SwiftUI

@main
struct StudyTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window - menu bar only
        Settings {
            EmptyView()
        }
    }
}
