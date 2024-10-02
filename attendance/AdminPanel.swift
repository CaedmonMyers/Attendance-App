import SwiftUI
import Firebase
import FirebaseFirestore
import UniformTypeIdentifiers


struct AdminPanelView: View {
    @StateObject private var viewModel = AdminPanelViewModel()
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.green.opacity(0.4), Color.blue.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Text("Admin Panel")
                            .foregroundStyle(Color.white)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    
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
                        
                        Button("Export to CSV") {
                            viewModel.exportToCSV()
                        }
                        .buttonStyle(CustomButtonStyle())
                        .tabItem {
                            Label("Export", systemImage: "person.2")
                        }
                        .tag(2)
                    }
                    .frame(height: geo.size.height * 0.95)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(20)
                    .padding()
                }
            }
            .onDisappear() {
                //viewModel.fetchUsers()
            }
        }
        .frame(minWidth: 800, minHeight: 700)
    }
}

struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var subteam: String
    var grade: String
    var studentId: String
    
    init(id: String = UUID().uuidString, name: String, email: String, subteam: String, grade: String, studentId: String) {
        self.id = id
        self.name = name
        self.email = email
        self.subteam = subteam
        self.grade = grade
        self.studentId = studentId
    }
}

// Update the UserManagementView
struct UserManagementView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var newUser = User(name: "", email: "", subteam: "", grade: "", studentId: "")
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 20) {
            List {
                ForEach(viewModel.users) { user in
                    UserRow(user: user, viewModel: viewModel, editingUser: $newUser, isEditing: $isEditing)
                }
                .onDelete(perform: viewModel.deleteUser)
            }
            .frame(height: 150)
            .listStyle(PlainListStyle())
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
            
            VStack(spacing: 10) {
                CustomTextField(text: $newUser.name, placeholder: "Name", onCommit: {})
                CustomTextField(text: $newUser.email, placeholder: "Email", onCommit: {})
                CustomTextField(text: $newUser.subteam, placeholder: "Subteam", onCommit: {})
                CustomTextField(text: $newUser.grade, placeholder: "Grade", onCommit: {})
                CustomTextField(text: $newUser.studentId, placeholder: "Student ID", onCommit: {})
                
                Button(isEditing ? "Update User" : "Add User") {
                    if isEditing {
                        viewModel.updateUser(newUser)
                        isEditing = false
                    } else {
                        viewModel.addUser(newUser)
                    }
                    newUser = User(name: "", email: "", subteam: "", grade: "", studentId: "")
                }
                .buttonStyle(CustomButtonStyle())
            }
            .padding()
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
        }
        .padding()
    }
}

struct UserRow: View {
    let user: User
    @ObservedObject var viewModel: AdminPanelViewModel
    @Binding var editingUser: User
    @Binding var isEditing: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Edit") {
                editingUser = user
                isEditing = true
            }
            .buttonStyle(CustomButtonStyle())
        }
        .padding()
        .background(Color.white.opacity(0.3))
        .cornerRadius(10)
    }
}

struct AttendanceView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var selectedDate: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Select Date", selection: $selectedDate) {
                ForEach(viewModel.attendanceDates, id: \.self) { date in
                    Text(date).tag(date)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .onChange(of: selectedDate) { newValue in
                viewModel.fetchAttendanceForDate(newValue)
            }
            
            List(viewModel.attendees, id: \.email) { attendee in
                VStack(alignment: .leading) {
                    Text(attendee.name)
                        .font(.headline)
                    Text(attendee.email)
                        .font(.subheadline)
                    Text("Student ID: \(attendee.studentId)")
                        .font(.caption)
                }
                .padding()
                .background(Color.white.opacity(0.3))
                .cornerRadius(10)
            }
            .listStyle(PlainListStyle())
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            viewModel.fetchAttendanceDates()
        }
    }
}

class AdminPanelViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var attendanceDates: [String] = []
    @Published var attendees: [User] = []
    @Published var selectedDate: String = ""
    
    private let db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
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
    
    func fetchAttendanceDates() {
        db.collection("Attendance").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting attendance dates: \(error.localizedDescription)")
            } else {
                self.attendanceDates = querySnapshot?.documents.compactMap { document -> String? in
                    if let date = (document.data()["date"] as? Timestamp)?.dateValue() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        return dateFormatter.string(from: date)
                    }
                    return nil
                }.sorted().reversed() ?? []
                
                if let mostRecentDate = self.attendanceDates.first {
                    self.selectedDate = mostRecentDate
                    self.fetchAttendanceForDate(mostRecentDate)
                }
            }
        }
    }
    
    func fetchAttendanceForDate(_ date: String) {
        db.collection("Attendance").document(date).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching attendance for date \(date): \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Attendance document does not exist for date \(date)")
                self.attendees = []
                return
            }
            
            do {
                let attendance = try document.data(as: Attendance.self)
                self.fetchAttendeesDetails(emails: attendance.attendees)
            } catch {
                print("Error decoding attendance document for date \(date): \(error.localizedDescription)")
                // Attempt to create Attendance with available data
                if let data = document.data(),
                   let attendees = data["attendees"] as? [String] {
                    self.fetchAttendeesDetails(emails: attendees)
                } else {
                    self.attendees = []
                }
            }
        }
    }
    
    func fetchAttendeesDetails(emails: [String]) {
        let group = DispatchGroup()
        var fetchedAttendees: [User] = []
        
        for email in emails {
            group.enter()
            db.collection("Users").document(email).getDocument { (document, error) in
                defer { group.leave() }
                if let error = error {
                    print("Error fetching user details for email \(email): \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        let user = try document.data(as: User.self)
                        fetchedAttendees.append(user)
                    } catch {
                        print("Error decoding user document for email \(email): \(error.localizedDescription)")
                        // Attempt to create User with available data
                        let data = document.data() ?? [:]
                        let user = User(
                            id: document.documentID,
                            name: data["name"] as? String ?? "",
                            email: email,
                            subteam: data["subteam"] as? String ?? "",
                            grade: data["grade"] as? String ?? "",
                            studentId: data["studentId"] as? String ?? ""
                        )
                        fetchedAttendees.append(user)
                    }
                } else {
                    fetchedAttendees.append(User(name: "Unknown", email: email, subteam: "Unknown", grade: "Unknown", studentId: "Unknown"))
                }
            }
        }
        
        group.notify(queue: .main) {
            self.attendees = fetchedAttendees
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
    

    #if os(macOS)

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
    #endif

    #if os(iOS)

    private func saveCSVToFile(_ csvString: String, viewController: UIViewController) {
        guard let data = csvString.data(using: .utf8) else {
            print("Error converting CSV string to data")
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("attendance_export.csv")
        
        do {
            try data.write(to: tempURL)
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
            viewController.present(documentPicker, animated: true, completion: nil)
            
            print("CSV file prepared for saving")
            // TODO: Show success message to user
        } catch {
            print("Error preparing CSV file for saving: \(error.localizedDescription)")
            // TODO: Show error to user
        }
    }
    #endif
}
