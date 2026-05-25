import SwiftUI
import UIKit
import WebKit

struct BrowserPageView: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > proxy.size.height {
                let sidebarWidth = floor(proxy.size.width * 0.5)

                HStack(spacing: 0) {
                    BrowserTabsSidebar(tabs: $tabs, selectedTabID: $selectedTabID)
                        .frame(width: sidebarWidth)

                    Divider()

                    selectedPage
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                selectedPage
            }
        }
        .background(.background)
    }

    private var selectedTab: BrowserTab? {
        tabs.first { $0.id == selectedTabID } ?? tabs.first
    }

    @ViewBuilder
    private var selectedPage: some View {
        if let selectedTab {
            WebView(url: selectedTab.url)
                .ignoresSafeArea(edges: .bottom)
        } else {
            Color.clear
        }
    }
}

private struct BrowserTabsSidebar: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?

    @State private var newTabAddress = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tabs")
                    .font(.headline)

                Spacer()

                Button(action: openNewTab) {
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .buttonStyle(.borderless)
                .disabled(newTabAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            VStack(alignment: .leading, spacing: 6) {
                TextField("New tab URL", text: $newTabAddress)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(openNewTab)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tabs) { tab in
                        TabRow(
                            tab: tab,
                            isSelected: tab.id == selectedTabID
                        ) {
                            selectedTabID = tab.id
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func openNewTab() {
        guard let url = URL.normalizedWebURL(from: newTabAddress) else {
            errorMessage = "Enter a valid URL."
            return
        }

        let tab = BrowserTab(url: url)
        tabs.append(tab)
        selectedTabID = tab.id
        newTabAddress = ""
        errorMessage = nil
    }
}

private struct TabRow: View {
    let tab: BrowserTab
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.body.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .background(.background, in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(tab.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.accentColor.opacity(0.16) : Color(uiColor: .tertiarySystemBackground),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        load(url, in: webView, context: context)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else {
            return
        }

        load(url, in: webView, context: context)
    }

    private func load(_ url: URL, in webView: WKWebView, context: Context) {
        context.coordinator.loadedURL = url
        webView.load(URLRequest(url: url))
    }

    final class Coordinator {
        var loadedURL: URL?
    }
}

#Preview {
    BrowserPageView(
        tabs: .constant([
            BrowserTab(url: URL(string: "https://example.com")!),
            BrowserTab(url: URL(string: "https://apple.com")!)
        ]),
        selectedTabID: .constant(nil)
    )
}
