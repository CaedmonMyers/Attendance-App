import SwiftUI
import Firebase
import FirebaseFirestore
import UniformTypeIdentifiers


struct AdminPanelView: View {
    @StateObject private var viewModel = AdminPanelViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            UserManagementView(viewModel: viewModel)
                .tabItem {
                    Label("User Management", systemImage: "person.3")
                }
                .tag(0)
            
            AttendanceView(viewModel: viewModel)
                .tabItem {
                    Label("Attendance", systemImage: "calendar")
                }
                .tag(1)
        }
        .padding()
    }
}

struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var grade: String
    var studentId: String
    
    init(id: String = UUID().uuidString, name: String, email: String, grade: String, studentId: String) {
        self.id = id
        self.name = name
        self.email = email
        self.grade = grade
        self.studentId = studentId
    }
}

// Update the UserManagementView
struct UserManagementView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var newUser = User(name: "", email: "", grade: "", studentId: "")
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.users) { user in
                    UserRow(user: user, viewModel: viewModel)
                }
                .onDelete(perform: viewModel.deleteUser)
            }
            
            Divider()
            
            VStack {
                TextField("Name", text: $newUser.name)
                TextField("Email", text: $newUser.email)
                TextField("Grade", text: $newUser.grade)
                TextField("Student ID", text: $newUser.studentId)
                
                Button(isEditing ? "Update User" : "Add User") {
                    if isEditing {
                        viewModel.updateUser(newUser)
                        isEditing = false
                    } else {
                        viewModel.addUser(newUser)
                    }
                    newUser = User(name: "", email: "", grade: "", studentId: "")
                }
            }
        }
    }
}

struct UserRow: View {
    let user: User
    @ObservedObject var viewModel: AdminPanelViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name)
                Text(user.email)
                    .font(.caption)
            }
            Spacer()
            Button("Edit") {
                viewModel.selectUserForEditing(user)
            }
        }
    }
}

struct AttendanceView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var selectedDate: String = ""
    
    var body: some View {
        VStack {
            Picker("Select Date", selection: $selectedDate) {
                ForEach(viewModel.attendanceDates, id: \.self) { date in
                    Text(date).tag(date)
                }
            }
            .onChange(of: selectedDate) { newValue in
                viewModel.fetchAttendanceForDate(newValue)
            }
            
            List(viewModel.attendees, id: \.email) { attendee in
                VStack(alignment: .leading) {
                    Text(attendee.name)
                    Text(attendee.email)
                    Text("Student ID: \(attendee.studentId)")
                }
            }
            
            Button("Export to CSV") {
                viewModel.exportToCSV()
            }
        }
        .onAppear {
            viewModel.fetchAttendanceDates()
        }
    }
}

class AdminPanelViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var attendanceDates: [String] = []
    @Published var attendees: [User] = []
    
    private let db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
    func fetchUsers() {
        db.collection("Users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting users: \(error)")
            } else {
                self.users = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
            }
        }
    }
    
    func addUser(_ user: User) {
        do {
            try db.collection("Users").document(user.email).setData(from: user)
            fetchUsers()
        } catch {
            print("Error adding user: \(error)")
        }
    }
    
    func updateUser(_ user: User) {
        do {
            try db.collection("Users").document(user.email).setData(from: user)
            fetchUsers()
        } catch {
            print("Error updating user: \(error)")
        }
    }
    
    func deleteUser(at offsets: IndexSet) {
        offsets.forEach { index in
            let user = users[index]
            db.collection("Users").document(user.email).delete()
        }
        fetchUsers()
    }
    
    func selectUserForEditing(_ user: User) {
        // Implement this method to handle user editing
    }
    
    func fetchAttendanceDates() {
        db.collection("Attendance").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting attendance dates: \(error)")
            } else {
                self.attendanceDates = querySnapshot?.documents.compactMap { $0.documentID }.sorted().reversed() ?? []
                if let firstDate = self.attendanceDates.first {
                    self.fetchAttendanceForDate(firstDate)
                }
            }
        }
    }
    
    func fetchAttendanceForDate(_ date: String) {
        db.collection("Attendance").document(date).getDocument { (document, error) in
            if let document = document, document.exists {
                if let attendance = try? document.data(as: Attendance.self) {
                    self.fetchAttendeesDetails(emails: attendance.attendees)
                }
            } else {
                print("Attendance document does not exist")
            }
        }
    }
    
    func fetchAttendeesDetails(emails: [String]) {
        let group = DispatchGroup()
        var fetchedAttendees: [User] = []
        
        for email in emails {
            group.enter()
            db.collection("Users").document(email).getDocument { (document, error) in
                if let document = document, document.exists {
                    if let user = try? document.data(as: User.self) {
                        fetchedAttendees.append(user)
                    }
                } else {
                    fetchedAttendees.append(User(name: "Unknown", email: email, grade: "Unknown", studentId: "Unknown"))
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.attendees = fetchedAttendees
        }
    }
}


extension AdminPanelViewModel {
    func exportToCSV() {
        fetchAllAttendanceData { result in
            switch result {
            case .success(let attendanceData):
                let csvString = self.createCSVString(from: attendanceData)
                self.saveCSVToFile(csvString)
            case .failure(let error):
                print("Error exporting to CSV: \(error.localizedDescription)")
                // TODO: Show error to user
            }
        }
    }
    
    private func fetchAllAttendanceData(completion: @escaping (Result<[String: [String]], Error>) -> Void) {
        db.collection("Attendance").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var attendanceData: [String: [String]] = [:]
            let group = DispatchGroup()
            
            for document in querySnapshot?.documents ?? [] {
                group.enter()
                let date = document.documentID
                if let attendance = try? document.data(as: Attendance.self) {
                    attendanceData[date] = attendance.attendees
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(.success(attendanceData))
            }
        }
    }
    
    private func createCSVString(from attendanceData: [String: [String]]) -> String {
        var csvString = "Name,Email,StudentID," + attendanceData.keys.sorted().joined(separator: ",") + "\n"
        
        for user in users {
            var row = "\(user.name),\(user.email),\(user.studentId),"
            for date in attendanceData.keys.sorted() {
                if attendanceData[date]?.contains(user.email) == true {
                    row += "✓,"
                } else {
                    row += "✗,"
                }
            }
            csvString += row.trimmingCharacters(in: [","]) + "\n"
        }
        
        return csvString
    }
    
    private func saveCSVToFile(_ csvString: String) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        savePanel.nameFieldStringValue = "attendance_export.csv"
        
        savePanel.begin { result in
            if result == .OK {
                guard let url = savePanel.url else { return }
                
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    print("CSV file saved successfully")
                    // TODO: Show success message to user
                } catch {
                    print("Error saving CSV file: \(error.localizedDescription)")
                    // TODO: Show error to user
                }
            }
        }
    }
}
