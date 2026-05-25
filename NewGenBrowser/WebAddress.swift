import Foundation

extension URL {
    static func normalizedWebURL(from rawValue: String) -> URL? {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isEmpty == false else {
            return nil
        }

        let candidate = trimmedValue.contains("://") ? trimmedValue : "https://\(trimmedValue)"
        guard
            let components = URLComponents(string: candidate),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            let host = components.host,
            host.isEmpty == false
        else {
            return nil
        }

        return components.url
    }
}
