import SwiftUI
import Firebase
import FirebaseFirestore

struct ContentView: View {
    @State private var isAdminPanelPresented = false
    @StateObject private var checkInViewModel = CheckInViewModel()
    
    var body: some View {
        NavigationView {
            CheckInView(viewModel: checkInViewModel)
        }
        .sheet(isPresented: $isAdminPanelPresented) {
            AdminPanelView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAdminPanel)) { _ in
            isAdminPanelPresented.toggle()
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
    private var allUsers: [User] = []
    private let db = Firestore.firestore()
    
    func fetchUsers() {
        db.collection("Users").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting users: \(error)")
            } else {
                self.allUsers = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
                self.filteredUsers = self.allUsers
            }
        }
    }
    
    func filterUsers(with searchText: String) {
        if searchText.isEmpty {
            filteredUsers = allUsers
        } else {
            filteredUsers = allUsers.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func checkIn(name: String) {
        guard let user = allUsers.first(where: { $0.name == name }) else { return }
        
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
        }
    }
}




struct Attendance: Codable {
    let date: Date
    let description: String
    let attendees: [String]
}



extension String {
    func capitalizedFirstLetterOfEachWord() -> String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}



