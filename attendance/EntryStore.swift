import SwiftUI


struct Entry: Codable, Identifiable {
    let id = UUID()
    var name: String
    let date: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy - h:mm a"
        return formatter.string(from: date)
    }
}

class EntryStore: ObservableObject {
    @Published var entries: [Entry] = []
    @AppStorage("showEntries") var showEntries = true
    
    init() {
        loadEntries()
    }
    
    func loadEntries() {
        if let savedEntries = UserDefaults.standard.data(forKey: "savedEntries") {
            if let decodedEntries = try? JSONDecoder().decode([Entry].self, from: savedEntries) {
                entries = decodedEntries
                return
            }
        }
        entries = []
    }
    
    func addEntry(_ name: String) {
        let newEntry = Entry(name: name, date: Date())
        entries.append(newEntry)
        saveEntries()
    }
    
    func updateEntry(_ entry: Entry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: Entry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "savedEntries")
        }
    }
    
    func clearAllEntries() {
        entries.removeAll()
        saveEntries()
    }
    
    func toggleEntriesVisibility() {
        showEntries.toggle()
    }
    
    func exportToCSV() -> String {
        var csvString = "Name,Date\n"
        for entry in entries {
            csvString += "\(entry.name),\(entry.formattedDate)\n"
        }
        return csvString
    }
}
