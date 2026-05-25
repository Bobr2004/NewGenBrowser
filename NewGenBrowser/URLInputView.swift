import SwiftUI

struct URLInputView: View {
    let onOpen: (URL) -> Void

    @State private var address = ""
    @State private var errorMessage: String?
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.tint)

                    Text("NewGen Browser")
                        .font(.largeTitle.bold())
                }

                VStack(spacing: 12) {
                    TextField("https://example.com", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .focused($isAddressFocused)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(openAddress)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: openAddress) {
                        Label("Open", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .frame(maxWidth: 420)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Browser")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isAddressFocused = true
            }
        }
    }

    private func openAddress() {
        guard let url = URL.normalizedWebURL(from: address) else {
            errorMessage = "Enter a valid website address."
            return
        }

        errorMessage = nil
        onOpen(url)
    }
}

#Preview {
    URLInputView { _ in }
}
