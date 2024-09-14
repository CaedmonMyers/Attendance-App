import SwiftUI


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
