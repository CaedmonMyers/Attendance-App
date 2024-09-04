import SwiftUI
import UniformTypeIdentifiers

struct Entry: Codable, Identifiable {
    let id = UUID()
    var name: String
    let date: Date
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormatter.string(from: entry.date)
            csvString += "\(entry.name),\(dateString)\n"
        }
        return csvString
    }
}

struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void
    
    var body: some View {
        TextField(placeholder, text: $text)
            .onSubmit(onCommit)
            .textFieldStyle(.plain)
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(20)
            .font(.system(size: 18))
            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
            #if os(macOS)
            .textFieldStyle(PlainTextFieldStyle())
            #else
            .textInputAutocapitalization(.words)
            #endif
    }
}

extension String {
    func capitalizedFirstLetterOfEachWord() -> String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}


struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.white.opacity(0.8))
            .foregroundStyle(LinearGradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(20)
            .font(.system(size: 18))
            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}


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
                    Text(entry.date, style: .date)
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

struct ContentView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @State private var newEntryName = ""
    @State private var csvData = ""
    @State private var isExporting = false
    @State private var successViewShown = false
    @State private var lastEntry = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(successViewShown ? 0.7: 0.4), Color.purple.opacity(successViewShown ? 0.7: 0.4)], startPoint: .leading, endPoint: .trailing)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.default, value: successViewShown)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack {
                            
                            Text("Check In")
                                .foregroundStyle(Color.white)
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .animation(.default, value: newEntryName)
                            
                            CustomTextField(text: $newEntryName, placeholder: "Enter a new item", onCommit: addEntry)
                                .frame(width: 300, height: 50)
                                .padding()
                                .animation(.default, value: newEntryName)
                                .onKeyPress(.escape) {
                                    newEntryName = ""
                                    return .handled
                                }
                            
                            if !newEntryName.isEmpty {
                                Button(action: addEntry) {
                                    Text("Add Entry")
                                }
                                .buttonStyle(CustomButtonStyle())
                                .animation(.default, value: newEntryName)
                            }
                            
                            if entryStore.showEntries {
                                ScrollView {
                                    VStack(spacing: 10) {
                                        ForEach(entryStore.entries) { entry in
                                            EntryView(entry: entry)
                                        }
                                    }
                                    .padding()
                                }
                                .frame(maxHeight: 300)
                            }
                        }.animation(.default, value: successViewShown)
                            .frame(width: successViewShown ? geo.size.width/3: geo.size.width)
                        
                        //if successViewShown {
                            VStack {
                                Text("Success!")
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .animation(.default, value: successViewShown)
                                    .padding(20)
                                
                                Text("You have been checked in as:")
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .animation(.default, value: successViewShown)
                                    .padding(10)
                                
//                                Text(entryStore.entries.last?.name ?? "")
//                                    .foregroundStyle(Color.white)
//                                    .font(.system(size: 30, weight: .black, design: .rounded))
//                                    .animation(.default, value: newEntryName)
                                TypewriterView(text: $lastEntry)
                                    .animation(.default, value: successViewShown)
                                
                            }.animation(.default, value: successViewShown)
                            .offset(x: successViewShown ? 0: geo.size.width)
                                .frame(width: geo.size.width/3)
                        //}
                        
                        //if successViewShown {
                            Spacer()
                                .animation(.default, value: successViewShown)
                                .offset(x: successViewShown ? 0: geo.size.width)
                                .frame(width: geo.size.width/3)
                        //}
                    }
                    
                    Spacer()
                    
                    if entryStore.showEntries {
                        Button("Export Data", action: prepareExport)
                            .buttonStyle(CustomButtonStyle())
                            .padding(20)
                    }
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: CSVFile(initialText: csvData),
                contentType: .commaSeparatedText,
                defaultFilename: "entries"
            ) { result in
                if case .success = result {
                    print("File exported successfully")
                } else {
                    print("File export failed")
                }
            }
        }
        .frame(minWidth: 400, minHeight: 600)
        .onAppear {
#if os(macOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.mainWindow?.toggleFullScreen(nil)
            }
#endif
        }
    }
    
    private func addEntry() {
        if !newEntryName.isEmpty {
            entryStore.addEntry(newEntryName.capitalizedFirstLetterOfEachWord())
            lastEntry = newEntryName
            newEntryName = ""
            successViewShown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                successViewShown = false
            }
        }
    }
    
    private func prepareExport() {
        csvData = entryStore.exportToCSV()
        isExporting = true
    }
}

struct CSVFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(EntryStore())
    }
}

struct TypewriterView: View {
    @Binding var text: String
    var typingDelay: Duration = .milliseconds(50)

    @State private var animatedText: AttributedString = ""
    @State private var typingTask: Task<Void, Error>?

    var body: some View {
        Text(animatedText)
            
            .onChange(of: text, {
                animatedText = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    animateText()
                }
            })
            .onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    animateText()
                }
            }
            .foregroundStyle(Color.white)
            .font(.system(size: 30, weight: .black, design: .rounded))
    }

    private func animateText() {
        typingTask?.cancel()

        typingTask = Task {
            let defaultAttributes = AttributeContainer()
            animatedText = AttributedString(text,
                                            attributes: defaultAttributes.foregroundColor(.clear)
            )

            var index = animatedText.startIndex
            while index < animatedText.endIndex {
                try Task.checkCancellation()

                // Update the style
                animatedText[animatedText.startIndex...index]
                    .setAttributes(defaultAttributes)

                // Wait
                try await Task.sleep(for: typingDelay)

                // Advance the index, character by character
                index = animatedText.index(afterCharacter: index)
            }
        }
    }
}
