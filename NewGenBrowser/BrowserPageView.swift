import SwiftUI
import UIKit
import WebKit

struct BrowserPageView: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?
    @State private var isTabsPanelVisible = false
    @State private var isActionsPanelVisible = false
    @State private var browserCommand: BrowserCommand?
    @State private var currentPageURL: URL?
    @State private var currentPageTitle: String?
    @State private var currentPageHasServiceWorker = false
    @State private var pinnedPages: [PinnedPage] = []
    @State private var savedApps = MockSavedApp.samples

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
            WebView(
                url: selectedTab.url,
                command: $browserCommand,
                currentURL: $currentPageURL,
                currentTitle: $currentPageTitle,
                hasServiceWorker: $currentPageHasServiceWorker
            )
                .ignoresSafeArea(edges: .bottom)
        } else {
            Color.clear
        }
    }

    private func browser(in size: CGSize) -> some View {
        let tabsPanelWidth = floor(size.width * 0.4)
        let actionsPanelWidth = floor(size.width * 0.2)

        return ZStack(alignment: .bottom) {
            selectedPage

            TabsPanelOverlay(
                tabs: $tabs,
                selectedTabID: $selectedTabID,
                pinnedPages: $pinnedPages,
                savedApps: $savedApps,
                isVisible: $isTabsPanelVisible,
                width: tabsPanelWidth,
                onOpenURL: openURL
            )

            BrowserActionsPanelOverlay(
                isVisible: $isActionsPanelVisible,
                width: actionsPanelWidth,
                onBack: goBack,
                onForward: goForward,
                onCopyLink: copyCurrentLink,
                hasServiceWorker: currentPageHasServiceWorker,
                onInstallOrPin: installOrPinCurrentPage
            )
        }
    }

    private func goBack() {
        browserCommand = BrowserCommand(action: .back)
    }

    private func goForward() {
        browserCommand = BrowserCommand(action: .forward)
    }

    private func copyCurrentLink() {
        guard let url = currentPageURL ?? selectedTab?.url else {
            return
        }

        UIPasteboard.general.string = url.absoluteString
        print("[BrowserActions] Copied link: \(url.absoluteString)")
    }

    private func installOrPinCurrentPage() {
        guard let url = currentPageURL ?? selectedTab?.url else {
            return
        }

        let title = normalizedPageTitle(for: url)

        if currentPageHasServiceWorker {
            let app = MockSavedApp(title: title, subtitle: url.host(percentEncoded: false) ?? url.absoluteString, systemImage: "app.badge.fill", url: url)
            guard savedApps.contains(where: { $0.url == url }) == false else {
                print("[BrowserActions] App is already saved: \(url.absoluteString)")
                return
            }

            savedApps.append(app)
            print("[BrowserActions] Saved app: \(title)")
        } else {
            let page = PinnedPage(title: title, subtitle: url.host(percentEncoded: false) ?? url.absoluteString, url: url)
            guard pinnedPages.contains(where: { $0.url == url }) == false else {
                print("[BrowserActions] Page is already pinned: \(url.absoluteString)")
                return
            }

            pinnedPages.insert(page, at: 0)
            print("[BrowserActions] Pinned page: \(title)")
        }
    }

    private func normalizedPageTitle(for url: URL) -> String {
        let trimmedTitle = currentPageTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedTitle, trimmedTitle.isEmpty == false {
            return trimmedTitle
        }

        return url.host(percentEncoded: false) ?? url.absoluteString
    }

    private func openURL(_ url: URL) {
        if let existingTab = tabs.first(where: { $0.url == url }) {
            selectedTabID = existingTab.id
            return
        }

        let tab = BrowserTab(url: url)
        tabs.append(tab)
        selectedTabID = tab.id
    }
}

private struct BrowserCommand: Equatable {
    let id = UUID()
    let action: Action

    enum Action {
        case back
        case forward
    }
}

private struct PinnedPage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let url: URL
}

private struct TabsPanelOverlay: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?
    @Binding var pinnedPages: [PinnedPage]
    @Binding var savedApps: [MockSavedApp]
    @Binding var isVisible: Bool

    let width: CGFloat
    let onOpenURL: (URL) -> Void

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
                    pinnedPages: $pinnedPages,
                    savedApps: $savedApps,
                    onOpenURL: onOpenURL,
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

private struct BrowserActionsPanelOverlay: View {
    @Binding var isVisible: Bool

    let width: CGFloat
    let onBack: () -> Void
    let onForward: () -> Void
    let onCopyLink: () -> Void
    let hasServiceWorker: Bool
    let onInstallOrPin: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            if isVisible {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        hidePanel()
                    }

                BrowserActionsPanel(
                    onBack: onBack,
                    onForward: onForward,
                    onCopyLink: onCopyLink,
                    hasServiceWorker: hasServiceWorker,
                    onInstallOrPin: onInstallOrPin
                )
                .frame(width: width)
                .frame(maxHeight: .infinity)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .gesture(
                    DragGesture(minimumDistance: 16, coordinateSpace: .local)
                        .onEnded { value in
                            guard value.translation.width > 40 else {
                                return
                            }

                            hidePanel()
                        }
                )
            } else {
                RightEdgeRevealZone(isVisible: $isVisible)
                    .ignoresSafeArea(edges: .trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .animation(.snappy(duration: 0.24), value: isVisible)
    }

    private func hidePanel() {
        withAnimation(.snappy(duration: 0.2)) {
            isVisible = false
        }
    }
}

private struct BrowserActionsPanel: View {
    let onBack: () -> Void
    let onForward: () -> Void
    let onCopyLink: () -> Void
    let hasServiceWorker: Bool
    let onInstallOrPin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                ActionPanelButton(
                    title: "Назад",
                    systemImage: "chevron.left",
                    action: onBack
                )

                ActionPanelButton(
                    title: "Вперед",
                    systemImage: "chevron.right",
                    action: onForward
                )
            }

            Spacer()

            VStack(spacing: 12) {
                ActionPanelButton(
                    title: "Копіювати",
                    systemImage: "doc.on.doc",
                    action: onCopyLink
                )

                ActionPanelButton(
                    title: hasServiceWorker ? "Завантажити" : "Закріпити",
                    systemImage: hasServiceWorker ? "arrow.down.circle" : "pin",
                    action: onInstallOrPin
                )
            }
            .padding(.bottom, 22)
        }
        .padding(.horizontal, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(alignment: .leading) {
            Divider()
        }
    }
}

private struct ActionPanelButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .frame(width: 34, height: 34)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(.primary)
            .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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

private struct RightEdgeRevealZone: UIViewRepresentable {
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
        recognizer.edges = .right
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
            let movedTowardCenter = translation.x < -72 || velocity.x < -320
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
            point.x >= bounds.width - edgeHitWidth
        }
    }
}

private struct BrowserTabsSidebar: View {
    @Binding var tabs: [BrowserTab]
    @Binding var selectedTabID: BrowserTab.ID?
    @Binding var pinnedPages: [PinnedPage]
    @Binding var savedApps: [MockSavedApp]

    let onOpenURL: (URL) -> Void
    let onSelectTab: () -> Void

    @State private var mode: SidebarMode = .tabs
    @State private var newTabAddress = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    mode = mode == .apps ? .tabs : .apps
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: mode == .apps ? "chevron.left" : "square.grid.3x3")
                        .font(.subheadline.weight(.semibold))

                    Text(mode == .apps ? "Вкладки" : "Застосунки")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .frame(height: 38)
                .foregroundStyle(.primary)
                .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack {
                Text(mode == .apps ? "Застосунки" : "Tabs")
                    .font(.headline)

                Spacer()

                if mode == .tabs {
                    Button(action: openNewTab) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.borderless)
                    .disabled(newTabAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if mode == .tabs {
                tabsList
            } else {
                SavedAppsGrid(apps: savedApps) { app in
                    onOpenURL(app.url)
                    onSelectTab()
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var tabsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            if pinnedPages.isEmpty == false {
                pinnedPagesList
            }

            newTabForm

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
    }

    private var pinnedPagesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Закріплені")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVStack(spacing: 8) {
                ForEach(pinnedPages) { page in
                    PinnedPageRow(page: page) {
                        onOpenURL(page.url)
                        onSelectTab()
                    }
                }
            }
        }
    }

    private var newTabForm: some View {
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

    private enum SidebarMode {
        case tabs
        case apps
    }
}

private struct MockSavedApp: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let url: URL

    static let samples = [
        MockSavedApp(title: "YouTube", subtitle: "youtube.com", systemImage: "play.rectangle.fill", url: URL(string: "https://youtube.com")!),
        MockSavedApp(title: "Maps", subtitle: "maps.google.com", systemImage: "map.fill", url: URL(string: "https://maps.google.com")!),
        MockSavedApp(title: "Mail", subtitle: "mail.google.com", systemImage: "envelope.fill", url: URL(string: "https://mail.google.com")!),
        MockSavedApp(title: "Docs", subtitle: "docs.google.com", systemImage: "doc.text.fill", url: URL(string: "https://docs.google.com")!),
        MockSavedApp(title: "Calendar", subtitle: "calendar.google.com", systemImage: "calendar", url: URL(string: "https://calendar.google.com")!)
    ]
}

private struct PinnedPageRow: View {
    let page: PinnedPage
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: "pin.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(page.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct SavedAppsGrid: View {
    let apps: [MockSavedApp]
    let onSelectApp: (MockSavedApp) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 42), spacing: 8),
        count: 3
    )

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(apps) { app in
                    SavedAppCell(app: app) {
                        onSelectApp(app)
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }
}

private struct SavedAppCell: View {
    let app: MockSavedApp
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: app.systemImage)
                    .font(.title3.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))

                Text(app.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(app.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .padding(.vertical, 9)
            .foregroundStyle(.primary)
            .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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
    @Binding var command: BrowserCommand?
    @Binding var currentURL: URL?
    @Binding var currentTitle: String?
    @Binding var hasServiceWorker: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            currentURL: $currentURL,
            currentTitle: $currentTitle,
            hasServiceWorker: $hasServiceWorker
        )
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
        if context.coordinator.loadedURL != url {
            load(url, in: webView, context: context)
        }

        guard context.coordinator.handledCommandID != command?.id else {
            return
        }

        context.coordinator.handledCommandID = command?.id

        switch command?.action {
        case .back:
            webView.goBack()
        case .forward:
            webView.goForward()
        case nil:
            break
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.serviceWorkerMessageName
        )
    }

    private func load(_ url: URL, in webView: WKWebView, context: Context) {
        context.coordinator.loadedURL = url
        context.coordinator.currentURL.wrappedValue = url
        context.coordinator.currentTitle.wrappedValue = nil
        context.coordinator.hasServiceWorker.wrappedValue = false
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let serviceWorkerMessageName = "serviceWorkerReporter"

        var loadedURL: URL?
        var handledCommandID: UUID?
        var currentURL: Binding<URL?>
        var currentTitle: Binding<String?>
        var hasServiceWorker: Binding<Bool>

        init(
            currentURL: Binding<URL?>,
            currentTitle: Binding<String?>,
            hasServiceWorker: Binding<Bool>
        ) {
            self.currentURL = currentURL
            self.currentTitle = currentTitle
            self.hasServiceWorker = hasServiceWorker
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            currentURL.wrappedValue = webView.url
            currentTitle.wrappedValue = webView.title
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
                hasServiceWorker.wrappedValue = false
                print("[ServiceWorker] Failed to inspect worker: \(error)")
                return
            }

            guard payload["supported"] as? Bool == true else {
                hasServiceWorker.wrappedValue = false
                print("[ServiceWorker] navigator.serviceWorker is unavailable on this page.")
                return
            }

            guard let fileNames = payload["fileNames"] as? [String], fileNames.isEmpty == false else {
                hasServiceWorker.wrappedValue = false
                print("[ServiceWorker] No registered service worker found.")
                return
            }

            hasServiceWorker.wrappedValue = true

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
