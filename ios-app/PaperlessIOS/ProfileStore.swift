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
    private var profileImageFilename: String?

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
    private let imageFilenameDefault = "profile-image.jpg"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(Snapshot.self, from: data) {
            displayName = saved.displayName
            currencyCode = saved.currencyCode
            notificationsEnabled = saved.notificationsEnabled
            profileImageFilename = saved.profileImageFilename
            profileImageData = loadImageData(filename: saved.profileImageFilename)
            return
        }

        // Legacy migration path for older builds that stored image bytes in defaults.
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let legacy = try? JSONDecoder().decode(LegacySnapshot.self, from: data) {
            displayName = legacy.displayName
            currencyCode = legacy.currencyCode
            notificationsEnabled = legacy.notificationsEnabled
            if let imageData = legacy.profileImageData {
                saveImageDataToDisk(imageData)
            } else {
                profileImageData = nil
            }
            persist()
            return
        }

        displayName = "Paperless User"
        currencyCode = "USD"
        notificationsEnabled = true
        profileImageData = nil
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
        guard let data else {
            removeImageFromDisk()
            profileImageData = nil
            profileImageFilename = nil
            return
        }
        saveImageDataToDisk(data)
    }

    private func persist() {
        let snapshot = Snapshot(
            displayName: displayName,
            currencyCode: currencyCode,
            notificationsEnabled: notificationsEnabled,
            profileImageFilename: profileImageFilename
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private struct Snapshot: Codable {
        let displayName: String
        let currencyCode: String
        let notificationsEnabled: Bool
        let profileImageFilename: String?
    }

    private struct LegacySnapshot: Codable {
        let displayName: String
        let currencyCode: String
        let notificationsEnabled: Bool
        let profileImageData: Data?
    }

    private var imageURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(imageFilenameDefault)
    }

    private func saveImageDataToDisk(_ data: Data) {
        let optimizedData = optimizeImageData(data)
        do {
            try optimizedData.write(to: imageURL, options: .atomic)
            profileImageFilename = imageFilenameDefault
            profileImageData = optimizedData
        } catch {
            // Keep in-memory fallback if disk write fails.
            profileImageFilename = nil
            profileImageData = optimizedData
        }
    }

    private func loadImageData(filename: String?) -> Data? {
        guard filename != nil else { return nil }
        return try? Data(contentsOf: imageURL)
    }

    private func removeImageFromDisk() {
        try? FileManager.default.removeItem(at: imageURL)
    }

    private func optimizeImageData(_ input: Data) -> Data {
        guard let image = UIImage(data: input) else { return input }
        let maxDimension: CGFloat = 512
        let size = image.size
        let maxSide = max(size.width, size.height)
        let scale = maxSide > maxDimension ? (maxDimension / maxSide) : 1
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.82) ?? input
    }
}
