import SwiftUI

struct URLInputView: View {
    let onOpen: (URL) -> Void

    @State private var address = ""
    @State private var errorMessage: String?
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        ZStack {
            HomeBackground()

            VStack(alignment: .leading, spacing: 26) {
                Spacer(minLength: 36)

                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 42, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.cyan)
                        .frame(width: 64, height: 64)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))

                    Text("NewGen")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Where to?")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))

                        TextField("Search or enter website", text: $address)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($isAddressFocused)
                            .foregroundStyle(.white)
                            .tint(.cyan)
                            .onSubmit(openAddress)

                        Button(action: openAddress) {
                            Image(systemName: "arrow.up.right")
                                .font(.body.weight(.bold))
                                .frame(width: 34, height: 34)
                                .foregroundStyle(.black)
                                .background(.cyan, in: Circle())
                        }
                        .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.38 : 1)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .frame(height: 58)
                    .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.13), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.26), radius: 26, y: 16)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal, 6)
                    }
                }

                QuickLaunchGrid { url in
                    onOpen(url)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onAppear {
            isAddressFocused = true
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

private struct HomeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.04, blue: 0.06),
                Color(red: 0.06, green: 0.08, blue: 0.11),
                Color(red: 0.02, green: 0.03, blue: 0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [.cyan.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
        }
        .overlay {
            RadialGradient(
                colors: [.blue.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

private struct QuickLaunchGrid: View {
    let onOpen: (URL) -> Void

    private let destinations = [
        QuickDestination(title: "Apple", subtitle: "apple.com", systemImage: "apple.logo", url: URL(string: "https://apple.com")!),
        QuickDestination(title: "YouTube", subtitle: "youtube.com", systemImage: "play.rectangle.fill", url: URL(string: "https://youtube.com")!),
        QuickDestination(title: "Docs", subtitle: "docs.google.com", systemImage: "doc.text.fill", url: URL(string: "https://docs.google.com")!),
        QuickDestination(title: "GitHub", subtitle: "github.com", systemImage: "chevron.left.forwardslash.chevron.right", url: URL(string: "https://github.com")!)
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(destinations) { destination in
                Button {
                    onOpen(destination.url)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: destination.systemImage)
                            .font(.headline.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.cyan)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(destination.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text(destination.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.48))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct QuickDestination: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let url: URL
}
