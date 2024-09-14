import SwiftUI


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
