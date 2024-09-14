import SwiftUI

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
                                
                                Button("Export Data", action: prepareExport)
                                    .buttonStyle(CustomButtonStyle())
                                    .padding(20)
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
            let capitalizedName = newEntryName.capitalizedFirstLetterOfEachWord()
            let newEntry = Entry(name: capitalizedName, date: Date())
            entryStore.addEntry(capitalizedName)
            lastEntry = capitalizedName
            newEntryName = ""
            successViewShown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successViewShown = false
            }
        }
    }
    
    private func prepareExport() {
        csvData = entryStore.exportToCSV()
        isExporting = true
    }
}


extension String {
    func capitalizedFirstLetterOfEachWord() -> String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}



