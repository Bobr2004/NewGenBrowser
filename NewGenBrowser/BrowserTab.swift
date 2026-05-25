import Foundation

struct BrowserTab: Identifiable, Equatable {
    let id: UUID
    let url: URL

    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
    }

    var title: String {
        url.host(percentEncoded: false) ?? url.absoluteString
    }

    var subtitle: String {
        url.absoluteString
    }
}
