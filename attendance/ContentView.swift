import SwiftUI
import Firebase
import FirebaseFirestore
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = CheckInViewModel()
    @State private var searchText = ""
    @State private var successViewShown = false
    @State private var lastEntry = ""
    @State private var isAdminPanelPresented = false
    @State private var selectedSuggestionIndex = 0
    
    var filteredSuggestions: [User] {
        searchText.count > 0 ? viewModel.filteredUsers.prefix(5).map { $0 } : []
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(successViewShown ? 0.7 : 0.4), Color.purple.opacity(successViewShown ? 0.7 : 0.4)], startPoint: .leading, endPoint: .trailing)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.default, value: successViewShown)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack {
                            Text("Check In")
                                .foregroundStyle(Color.white)
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .animation(.default, value: searchText)
                                .animation(.default, value: filteredSuggestions.count)
                            
                            VStack {
                                VStack(spacing: 0) {
                                    TextField("Enter your name or ID", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .onChange(of: searchText) { _ in
                                            viewModel.filterUsers(with: searchText)
                                            selectedSuggestionIndex = 0
                                        }
                                        .onSubmit(checkIn)
                                    
                                    if !filteredSuggestions.isEmpty {
                                        Divider()
                                            .padding(.vertical, 10)
                                        
                                        ForEach(Array(filteredSuggestions.enumerated()), id: \.element.id) { index, user in
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(user.name)
                                                        .font(.headline)
                                                    Text("Subteam: \(user.subteam)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 5)
                                            .background {
                                                if index == selectedSuggestionIndex {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                                                        .padding(-7)
                                                }
                                            }
                                            .onTapGesture {
                                                selectedSuggestionIndex = index
                                                checkIn()
                                            }
                                        }
                                    }
                                }.padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(20)
                                    .font(.system(size: 18))
                                    .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .animation(.default)
                            }
                            .frame(width: 300)
                            .frame(height: !filteredSuggestions.isEmpty ? nil : 50)
                            
                            if !filteredSuggestions.isEmpty {
                                Button(action: checkIn) {
                                    Text("Check In")
                                }
                                .buttonStyle(CustomButtonStyle())
                                .padding(.top)
                                .animation(.default, value: searchText)
                                .animation(.default, value: filteredSuggestions.count)
                                //.animation(.default)
                            }
                        }
                        .animation(.default, value: successViewShown)
                        .frame(width: successViewShown ? geo.size.width/3: geo.size.width)
                        
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
                            
                            TypewriterView(text: $lastEntry)
                                .animation(.default, value: successViewShown)
                            
                        }.animation(.default, value: successViewShown)
                            .offset(x: successViewShown ? 0: geo.size.width)
                            .frame(width: geo.size.width/3)
                        
                        Spacer()
                            .animation(.default, value: successViewShown)
                            .offset(x: successViewShown ? 0: geo.size.width)
                            .frame(width: geo.size.width/3)
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(minWidth: 400, minHeight: 600)
        .onAppear {
            //viewModel.fetchUsers()
#if os(macOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.mainWindow?.toggleFullScreen(nil)
            }
#endif
        }
        .sheet(isPresented: $isAdminPanelPresented) {
            AdminPanelView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAdminPanel)) { _ in
            isAdminPanelPresented.toggle()
        }
        .onKeyPress(.upArrow) {
            moveSelection(direction: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(direction: 1)
            return .handled
        }
    }
    
    private func moveSelection(direction: Int) {
        if !filteredSuggestions.isEmpty {
            selectedSuggestionIndex = (selectedSuggestionIndex + direction + filteredSuggestions.count) % filteredSuggestions.count
        }
    }
    
    private func checkIn() {
        if !filteredSuggestions.isEmpty {
            let selectedUser = filteredSuggestions[selectedSuggestionIndex]
            viewModel.checkIn(name: selectedUser.name)
            lastEntry = selectedUser.name
            searchText = ""
            successViewShown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successViewShown = false
            }
        }
    }
}




struct CheckInView: View {
    @ObservedObject var viewModel: CheckInViewModel
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            TextField("Enter your name", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) { newValue in
                    viewModel.filterUsers(with: newValue)
                }
            
            List(viewModel.filteredUsers, id: \.email) { user in
                Text(user.name)
                    .onTapGesture {
                        searchText = user.name
                    }
            }
            
            Button("Continue") {
                viewModel.checkIn(name: searchText)
            }
            .disabled(searchText.isEmpty)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}

class CheckInViewModel: ObservableObject {
    @Published var filteredUsers: [User] = []
    @Published var attendees: [User] = []
    @AppStorage("showEntries") var showEntries = true
    private var users: [User] = []
    private let db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
//    func fetchUsers() {
//        db.collection("Users").getDocuments { [weak self] (querySnapshot, error) in
//            guard let self = self else { return }
//            if let error = error {
//                print("Error getting users: \(error)")
//            } else {
//                self.allUsers = querySnapshot?.documents.compactMap { document in
//                    try? document.data(as: User.self)
//                } ?? []
//                self.filteredUsers = self.allUsers
//            }
//        }
//    }
    
    func fetchUsers() {
        db.collection("Users").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting users: \(error.localizedDescription)")
            } else {
                self.users = querySnapshot?.documents.compactMap { document in
                    do {
                        let user = try document.data(as: User.self)
                        return user
                    } catch {
                        print("Error decoding user document \(document.documentID): \(error.localizedDescription)")
                        // Attempt to create a User with available data
                        let data = document.data()
                        return User(
                            id: document.documentID,
                            name: data["name"] as? String ?? "",
                            email: data["email"] as? String ?? "",
                            subteam: data["subteam"] as? String ?? "",
                            grade: data["grade"] as? String ?? "",
                            studentId: data["studentId"] as? String ?? ""
                        )
                    }
                } ?? []
                print("Fetched \(self.users.count) users")
            }
        }
    }
    
    
    func filterUsers(with searchText: String) {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            let lowercasedSearchText = searchText.lowercased()
            
            filteredUsers = users.filter { user in
                user.name.lowercased().contains(lowercasedSearchText) ||
                user.studentId.lowercased().contains(lowercasedSearchText) ||
                user.email.lowercased().hasPrefix(lowercasedSearchText)
            }.sorted { user1, user2 in
                let name1 = user1.name.lowercased()
                let name2 = user2.name.lowercased()
                let email1 = user1.email.lowercased()
                let email2 = user2.email.lowercased()
                
                // Helper function to determine match type
                func matchType(for user: User) -> Int {
                    if user.name.lowercased().hasPrefix(lowercasedSearchText) { return 0 }
                    if user.email.lowercased().hasPrefix(lowercasedSearchText) { return 1 }
                    return 2
                }
                
                let type1 = matchType(for: user1)
                let type2 = matchType(for: user2)
                
                if type1 != type2 {
                    return type1 < type2
                }
                
                // If match types are the same, sort based on the type
                switch type1 {
                case 0: // Both are name prefix matches
                    return name1 < name2
                case 1: // Both are email prefix matches
                    return email1 < email2
                default: // Both are partial matches
                    // Find the earliest occurrence in name
                    let index1 = name1.range(of: lowercasedSearchText, options: .caseInsensitive)?.lowerBound ?? name1.endIndex
                    let index2 = name2.range(of: lowercasedSearchText, options: .caseInsensitive)?.lowerBound ?? name2.endIndex
                    
                    if index1 != index2 {
                        return index1 < index2
                    }
                    
                    // If positions are equal, sort alphabetically by name
                    return name1 < name2
                }
            }
        }
    }
    
    func checkIn(name: String) {
        guard let user = users.first(where: { $0.name == name }) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let attendanceRef = db.collection("Attendance").document(dateString)
        
        attendanceRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                // Update existing document
                attendanceRef.updateData([
                    "attendees": FieldValue.arrayUnion([user.email])
                ])
            } else {
                // Create new document
                let newAttendance = Attendance(date: Date(), description: "Check-in for \(dateString)", attendees: [user.email])
                try? attendanceRef.setData(from: newAttendance)
            }
            self.attendees.append(user)
        }
    }
    
    func toggleEntriesVisibility() {
        showEntries.toggle()
    }
    
    func exportToCSV() -> String {
        var csvString = "Name,Email,Grade,Student ID,Date\n"
        for attendee in attendees {
            csvString += "\(attendee.name),\(attendee.email),\(attendee.grade),\(attendee.studentId),\(Date().formatted(date: .numeric, time: .shortened))\n"
        }
        return csvString
    }
}




struct Attendance: Codable {
    let date: Date
    let description: String
    let attendees: [String]

    enum CodingKeys: String, CodingKey {
        case date
        case description
        case attendees
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        attendees = try container.decodeIfPresent([String].self, forKey: .attendees) ?? []
    }

    init(date: Date = Date(), description: String = "", attendees: [String] = []) {
        self.date = date
        self.description = description
        self.attendees = attendees
    }
}



extension String {
    func capitalizedFirstLetterOfEachWord() -> String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
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
