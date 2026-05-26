import SwiftUI
import UIKit
import WebKit

struct BrowserPageView: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?
    @State private var isBottomBarVisible = false
    @State private var isTabsPanelVisible = false

    var body: some View {
        GeometryReader { proxy in
            browser(in: proxy.size)
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

    private func browser(in size: CGSize) -> some View {
        let tabsPanelWidth = floor(size.width * 0.4)

        return ZStack(alignment: .bottom) {
            selectedPage

            if isBottomBarVisible {
                BrowserActionBar()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            BottomRightRevealZone(
                isBottomBarVisible: $isBottomBarVisible
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            TabsPanelOverlay(
                tabs: $tabs,
                selectedTabID: $selectedTabID,
                isVisible: $isTabsPanelVisible,
                width: tabsPanelWidth
            )
        }
    }
}

private struct TabsPanelOverlay: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?
    @Binding var isVisible: Bool

    let width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            if isVisible {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.2)) {
                            isVisible = false
                        }
                    }

                BrowserTabsSidebar(
                    tabs: $tabs,
                    selectedTabID: $selectedTabID,
                    onSelectTab: hidePanel
                )
                    .frame(width: width)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .gesture(
                        DragGesture(minimumDistance: 16, coordinateSpace: .local)
                            .onEnded { value in
                                guard value.translation.width < -40 else {
                                    return
                                }

                                withAnimation(.snappy(duration: 0.22)) {
                                    isVisible = false
                                }
                            }
                    )
            } else {
                LeftEdgeRevealZone(isVisible: $isVisible)
                    .ignoresSafeArea(edges: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.24), value: isVisible)
    }

    private func hidePanel() {
        withAnimation(.snappy(duration: 0.2)) {
            isVisible = false
        }
    }
}

private struct LeftEdgeRevealZone: UIViewRepresentable {
    @Binding var isVisible: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isVisible: $isVisible)
    }

    func makeUIView(context: Context) -> EdgePanView {
        let view = EdgePanView()
        let recognizer = UIScreenEdgePanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleEdgePan(_:))
        )
        recognizer.edges = .left
        recognizer.delegate = context.coordinator
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: EdgePanView, context: Context) {
        context.coordinator.isVisible = $isVisible
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isVisible: Binding<Bool>

        init(isVisible: Binding<Bool>) {
            self.isVisible = isVisible
        }

        @objc func handleEdgePan(_ recognizer: UIScreenEdgePanGestureRecognizer) {
            guard recognizer.state == .ended else {
                return
            }

            let translation = recognizer.translation(in: recognizer.view)
            let velocity = recognizer.velocity(in: recognizer.view)
            let movedTowardCenter = translation.x > 72 || velocity.x > 320
            let stayedHorizontal = abs(translation.y) < 90

            guard movedTowardCenter && stayedHorizontal else {
                return
            }

            withAnimation(.snappy(duration: 0.24)) {
                isVisible.wrappedValue = true
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }

    final class EdgePanView: UIView {
        private let edgeHitWidth: CGFloat = 44

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isOpaque = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            point.x <= edgeHitWidth
        }
    }
}

private struct BrowserActionBar: View {
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "chevron.left")
            Image(systemName: "chevron.right")
            Image(systemName: "arrow.clockwise")
            Spacer(minLength: 0)
            Image(systemName: "square.on.square")
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 18)
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .padding(8)
                .foregroundStyle(.secondary)
        }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}

private struct BottomRightRevealZone: View {
    @Binding var isBottomBarVisible: Bool

    var body: some View {
        Color.clear
            .frame(width: 96, height: 96)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18, coordinateSpace: .local)
                    .onEnded { value in
                        guard shouldRevealBar(for: value) else {
                            return
                        }

                        withAnimation(.snappy(duration: 0.24)) {
                            isBottomBarVisible = true
                        }
                    }
            )
    }

    private func shouldRevealBar(for value: DragGesture.Value) -> Bool {
        let translation = value.translation

        let movedLeft = translation.width < -44
        let movedUp = translation.height < -26

        return movedLeft && movedUp
    }
}

private struct BrowserTabsSidebar: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?
    let onSelectTab: () -> Void

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
                            onSelectTab()
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
        onSelectTab()
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
        configuration.userContentController.add(
            context.coordinator,
            name: Coordinator.serviceWorkerMessageName
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        load(url, in: webView, context: context)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else {
            return
        }

        load(url, in: webView, context: context)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.serviceWorkerMessageName
        )
    }

    private func load(_ url: URL, in webView: WKWebView, context: Context) {
        context.coordinator.loadedURL = url
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let serviceWorkerMessageName = "serviceWorkerReporter"

        var loadedURL: URL?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            logServiceWorkerFileName(in: webView)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.serviceWorkerMessageName else {
                return
            }

            guard let payload = message.body as? [String: Any] else {
                print("[ServiceWorker] Unexpected payload: \(message.body)")
                return
            }

            if let error = payload["error"] as? String {
                print("[ServiceWorker] Failed to inspect worker: \(error)")
                return
            }

            guard payload["supported"] as? Bool == true else {
                print("[ServiceWorker] navigator.serviceWorker is unavailable on this page.")
                return
            }

            guard let fileNames = payload["fileNames"] as? [String], fileNames.isEmpty == false else {
                print("[ServiceWorker] No registered service worker found.")
                return
            }

            for fileName in fileNames {
                print("[ServiceWorker] Worker file: \(fileName)")
            }
        }

        private func logServiceWorkerFileName(in webView: WKWebView) {
            let script = """
            (() => {
                const report = (payload) => {
                    window.webkit.messageHandlers.\(Self.serviceWorkerMessageName).postMessage(payload);
                };

                if (!("serviceWorker" in navigator)) {
                    report({ supported: false });
                    return;
                }

                navigator.serviceWorker.getRegistrations()
                    .then((registrations) => {
                        const urls = registrations.flatMap((registration) => {
                            return [
                                registration.active,
                                registration.waiting,
                                registration.installing
                            ]
                                .filter(Boolean)
                                .map((worker) => worker.scriptURL);
                        });

                        const fileNames = [...new Set(urls)].map((url) => {
                            const path = new URL(url, window.location.href).pathname;
                            return path.split("/").filter(Boolean).pop() || url;
                        });

                        report({ supported: true, fileNames });
                    })
                    .catch((error) => {
                        report({ supported: true, error: String(error) });
                    });
            })();
            """

            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    print("[ServiceWorker] JavaScript evaluation failed: \(error.localizedDescription)")
                }
            }
        }
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
