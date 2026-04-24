import Foundation

@MainActor
final class ReceiptStore: ObservableObject {
    @Published private(set) var receipts: [ReceiptModel] = []

    private let storageKey = "paperless.receipts.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func add(_ receipt: ReceiptModel) {
        receipts.insert(receipt, at: 0)
        persist()
    }

    func replaceAll(with updated: [ReceiptModel]) {
        receipts = updated
        persist()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? decoder.decode([ReceiptModel].self, from: data)
        else {
            // First run fallback so the app is immediately usable.
            receipts = MockData.receipts
            persist()
            return
        }
        receipts = decoded
    }

    private func persist() {
        guard let data = try? encoder.encode(receipts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
