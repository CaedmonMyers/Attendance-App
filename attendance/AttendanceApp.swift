import SwiftUI
import Firebase

@main
struct AttendanceApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Open Admin Panel") {
                    NotificationCenter.default.post(name: .openAdminPanel, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let openAdminPanel = Notification.Name("openAdminPanel")
}
