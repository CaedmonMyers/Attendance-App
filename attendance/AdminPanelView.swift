import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject private var attendanceStore: AttendanceStore
    @State private var selectedTab = 0
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Text("Close")
            }

            TabView(selection: $selectedTab) {
                ExportView()
                    .tabItem {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .tag(0)
                
                UserManagementView()
                    .tabItem {
                        Label("Users", systemImage: "person.3")
                    }
                    .tag(1)
            }
            .frame(width: 600, height: 400)
        }
    }
}

struct ExportView: View {
//    @EnvironmentObject private var attendanceStore: AttendanceStore
    @StateObject var attendanceStore = AttendanceStore()
    @State private var csvString = ""
    
    var body: some View {
        VStack {
            Button("Generate CSV") {
                csvString = attendanceStore.exportCSV()
            }
            .buttonStyle(CustomButtonStyle())
            
            if !csvString.isEmpty {
                TextEditor(text: .constant(csvString))
                    .font(.system(.body, design: .monospaced))
                    .padding()
                
                Button("Save CSV") {
                    saveCSV()
                }
                .buttonStyle(CustomButtonStyle())
            }
        }
        .padding()
    }
    
    private func saveCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "attendance.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Error saving CSV: \(error)")
                }
            }
        }
    }
}

struct UserManagementView: View {
    //@EnvironmentObject private var attendanceStore: AttendanceStore
    @StateObject var attendanceStore = AttendanceStore()
    @State private var showingAddUser = false
    @State private var editingUser: User?
    
    var body: some View {
        VStack {
            List {
                ForEach(attendanceStore.users.sorted { $0.name < $1.name }) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        Text(user.subteam)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingUser = user
                    }
                }
                .onDelete(perform: deleteUser)
            }
            
            Button("Add User") {
                showingAddUser = true
            }
            .buttonStyle(CustomButtonStyle())
        }
        .sheet(isPresented: $showingAddUser) {
            UserFormView(user: nil)
        }
        .sheet(item: $editingUser) { user in
            UserFormView(user: user)
        }
    }
    
    private func deleteUser(at offsets: IndexSet) {
        offsets.forEach { index in
            let user = attendanceStore.users.sorted { $0.name < $1.name }[index]
            attendanceStore.deleteUser(user)
        }
    }
}

struct UserFormView: View {
    //@EnvironmentObject private var attendanceStore: AttendanceStore
    @StateObject var attendanceStore = AttendanceStore()
    @Environment(\.presentationMode) var presentationMode
    
    let user: User?
    @State private var id = ""
    @State private var name = ""
    @State private var subteam = ""
    
    var body: some View {
        Form {
            TextField("ID", text: $id)
            TextField("Name", text: $name)
            TextField("Subteam", text: $subteam)
            
            Button(user == nil ? "Add User" : "Update User") {
                            let newUser = User(id: id, name: name, subteam: subteam)
                            if user == nil {
                                attendanceStore.addUser(newUser)
                            } else {
                                attendanceStore.updateUser(newUser)
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(CustomButtonStyle())
                    }
                    .padding()
                    .frame(width: 300, height: 200)
                    .onAppear {
                        if let user = user {
                            id = user.id
                            name = user.name
                            subteam = user.subteam
                        }
                    }
                }
            }



