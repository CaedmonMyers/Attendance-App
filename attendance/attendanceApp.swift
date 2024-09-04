

import SwiftUI

@main
struct TextEntryApp: App {
    @StateObject private var entryStore = EntryStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(entryStore)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .undoRedo) {}
            
            CommandMenu("Entries") {
                Button("Clear All Entries") {
                    entryStore.clearAllEntries()
                }
                //.keyboardShortcut("D", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Toggle Entries Visibility") {
                    withAnimation {
                        entryStore.toggleEntriesVisibility()
                    }
                }
                .keyboardShortcut("E", modifiers: [.command])
            }
        }
    }
}
