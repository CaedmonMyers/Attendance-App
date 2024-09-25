import SwiftUI
import Firebase

class AttendanceStore: ObservableObject {
    @Published var checkedInUser: User?
    @Published var users: [User] = []
    
    private var db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
    func checkInUser(id: String) {
        let docId = getCurrentDateString()
        
        db.collection("Users").document(id).getDocument { (document, error) in
            if let document = document, document.exists {
                let user = self.userFrom(document)
                
                self.db.collection("Events").document(docId).updateData([
                    "attendees": FieldValue.arrayUnion([id])
                ]) { error in
                    if let error = error {
                        print("Error checking in user: \(error)")
                        // If the document doesn't exist, create it
                        self.db.collection("Events").document(docId).setData([
                            "date": Timestamp(date: Date()),
                            "attendees": [id]
                        ]) { error in
                            if let error = error {
                                print("Error creating event document: \(error)")
                            } else {
                                self.checkedInUser = user
                            }
                        }
                    } else {
                        self.checkedInUser = user
                    }
                }
            }
        }
    }
    
    func fetchUsers() {
        db.collection("Users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting users: \(error)")
            } else {
                self.users = querySnapshot?.documents.compactMap { self.userFrom($0) } ?? []
            }
        }
    }
    
    func addUser(_ user: User) {
        db.collection("Users").document(user.id).setData(user.dictionary) { error in
            if let error = error {
                print("Error adding user: \(error)")
            } else {
                self.users.append(user)
            }
        }
    }
    
    func updateUser(_ user: User) {
        db.collection("Users").document(user.id).setData(user.dictionary) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                    self.users[index] = user
                }
            }
        }
    }
    
    func deleteUser(_ user: User) {
        db.collection("Users").document(user.id).delete() { error in
            if let error = error {
                print("Error deleting user: \(error)")
            } else {
                self.users.removeAll { $0.id == user.id }
            }
        }
    }
    
    func exportCSV() -> String {
        var csv = "Name,Subteam"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Add date columns
        db.collection("Events").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting events: \(error)")
            } else {
                let sortedDocs = querySnapshot?.documents.sorted {
                    dateFormatter.date(from: $0.documentID)! < dateFormatter.date(from: $1.documentID)!
                }
                sortedDocs?.forEach { doc in
                    csv += ",\(doc.documentID)"
                }
                
                csv += "\n"
                
                // Add user rows
                self.users.forEach { user in
                    csv += "\(user.name),\(user.subteam)"
                    sortedDocs?.forEach { doc in
                        let event = self.eventFrom(doc)
                        csv += event.attendees.contains(user.id) ? ",✓" : ","
                    }
                    csv += "\n"
                }
            }
        }
        
        return csv
    }
    
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
    
    private func eventFrom(_ document: DocumentSnapshot) -> Event {
        let data = document.data()!
        return Event(
            id: document.documentID,
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            attendees: data["attendees"] as? [String] ?? []
        )
    }
    
    private func userFrom(_ document: DocumentSnapshot) -> User {
        let data = document.data()!
        return User(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            subteam: data["subteam"] as? String ?? ""
        )
    }
}

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let subteam: String
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "subteam": subteam
        ]
    }
}

struct Event: Identifiable, Codable {
    let id: String
    let date: Date
    var attendees: [String]
    
    var dictionary: [String: Any] {
        return [
            "date": Timestamp(date: date),
            "attendees": attendees
        ]
    }
}
