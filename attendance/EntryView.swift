import SwiftUI


struct EntryView: View {
    let entry: Entry
    @EnvironmentObject private var entryStore: EntryStore
    @State private var isEditing = false
    @State private var editedName = ""
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Edit entry", text: $editedName, onCommit: {
                    var updatedEntry = entry
                    updatedEntry.name = editedName
                    entryStore.updateEntry(updatedEntry)
                    isEditing = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                VStack(alignment: .leading) {
                    Text(entry.name)
                        .font(.headline)
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white.opacity(0.6))
        .cornerRadius(10)
        .contextMenu {
            Button("Edit") {
                editedName = entry.name
                isEditing = true
            }
            Button("Delete", role: .destructive) {
                entryStore.deleteEntry(entry)
            }
        }
    }
}
