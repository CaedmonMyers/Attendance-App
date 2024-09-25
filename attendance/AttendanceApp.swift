import SwiftUI
import Firebase

@main
struct AttendanceApp: App {
    @StateObject private var attendanceStore = AttendanceStore()
    @State private var showAdminPanel = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(attendanceStore)
                .sheet(isPresented: $showAdminPanel) {
                    AdminPanelView()
                }
        }
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Open Admin Panel") {
                    showAdminPanel = true
                }
                .keyboardShortcut("E", modifiers: [.command])
            }
        }
    }
}
