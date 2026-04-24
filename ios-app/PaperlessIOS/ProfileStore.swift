import Foundation
import UIKit

@MainActor
final class ProfileStore: ObservableObject {
    @Published var displayName: String {
        didSet { persist() }
    }
    @Published var currencyCode: String {
        didSet { persist() }
    }
    @Published var notificationsEnabled: Bool {
        didSet { persist() }
    }
    @Published private(set) var profileImageData: Data? {
        didSet { persist() }
    }

    static let supportedCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
    private static let languageDisplayNamesByCode: [String: String] = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "ja": "Japanese",
        "ko": "Korean"
    ]

    private let storageKey = "paperless.profile.v1"

    init() {
        if
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode(Snapshot.self, from: data)
        {
            displayName = saved.displayName
            currencyCode = saved.currencyCode
            notificationsEnabled = saved.notificationsEnabled
            profileImageData = saved.profileImageData
        } else {
            displayName = "Paperless User"
            currencyCode = "USD"
            notificationsEnabled = true
            profileImageData = nil
        }
    }

    var profileImage: UIImage? {
        guard let profileImageData else { return nil }
        return UIImage(data: profileImageData)
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "P"
        let second = parts.dropFirst().first?.first.map(String.init) ?? "U"
        return (first + second).uppercased()
    }

    var languageDisplay: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = preferred.split(separator: "-").first.map(String.init)?.lowercased() ?? "en"
        return Self.languageDisplayNamesByCode[code] ?? "English"
    }

    func setProfileImage(_ data: Data?) {
        profileImageData = data
    }

    private func persist() {
        let snapshot = Snapshot(
            displayName: displayName,
            currencyCode: currencyCode,
            notificationsEnabled: notificationsEnabled,
            profileImageData: profileImageData
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private struct Snapshot: Codable {
        let displayName: String
        let currencyCode: String
        let notificationsEnabled: Bool
        let profileImageData: Data?
    }
}
