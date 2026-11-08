import SwiftUI

extension View {
    /// Shows an alert whenever `message` is non-nil and clears it on dismiss.
    func messageAlert(_ title: String, message: Binding<String?>) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented { message.wrappedValue = nil }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(message.wrappedValue ?? "")
            }
        )
    }

    func errorAlert(_ message: Binding<String?>) -> some View {
        messageAlert("Something went wrong", message: message)
    }
}
