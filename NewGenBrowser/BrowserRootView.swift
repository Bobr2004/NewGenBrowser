import SwiftUI

struct BrowserRootView: View {
    @State private var tabs: [BrowserTab] = []
    @State private var selectedTabID: BrowserTab.ID?

    var body: some View {
        Group {
            if tabs.isEmpty {
                URLInputView { url in
                    let tab = BrowserTab(url: url)
                    tabs = [tab]
                    selectedTabID = tab.id
                }
            } else {
                BrowserPageView(tabs: $tabs, selectedTabID: $selectedTabID)
            }
        }
        .animation(.snappy, value: tabs.isEmpty)
    }
}
