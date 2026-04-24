import Foundation

struct ReceiptItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let quantity: Int
    let unitPrice: Double

    var total: Double { Double(quantity) * unitPrice }

    init(id: UUID = UUID(), name: String, quantity: Int, unitPrice: Double) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
}

struct ReceiptModel: Identifiable, Hashable, Codable {
    let id: UUID
    let storeName: String
    let total: Double
    let paymentMethod: String
    let purchaseDate: Date
    let items: [ReceiptItem]
    let storeAddress: String

    init(
        id: UUID = UUID(),
        storeName: String,
        total: Double,
        paymentMethod: String,
        purchaseDate: Date,
        items: [ReceiptItem],
        storeAddress: String
    ) {
        self.id = id
        self.storeName = storeName
        self.total = total
        self.paymentMethod = paymentMethod
        self.purchaseDate = purchaseDate
        self.items = items
        self.storeAddress = storeAddress
    }
}

private struct QRReceiptItemPayload: Decodable {
    let name: String
    let quantity: Int?
    let unit_price: Double?
    let total: Double?
}

private struct QRReceiptPayload: Decodable {
    let store_name: String
    let store_address: String?
    let purchase_date: String?
    let items: [QRReceiptItemPayload]
    let total: Double
    let payment_method: String?
}

enum QRParseError: LocalizedError {
    case invalidFormat
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid QR code format. Expected receipt JSON data."
        case .missingRequiredFields:
            return "QR code is missing required receipt fields."
        }
    }
}

extension ReceiptModel {
    static func fromQRCode(_ rawValue: String) throws -> ReceiptModel {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw QRParseError.invalidFormat
        }

        let decoder = JSONDecoder()
        let payload: QRReceiptPayload
        do {
            payload = try decoder.decode(QRReceiptPayload.self, from: data)
        } catch {
            throw QRParseError.invalidFormat
        }

        guard !payload.store_name.isEmpty, payload.total.isFinite else {
            throw QRParseError.missingRequiredFields
        }

        let formatter = ISO8601DateFormatter()
        let purchaseDate = payload.purchase_date.flatMap { formatter.date(from: $0) } ?? Date()
        let mappedItems: [ReceiptItem] = payload.items.map { item in
            let quantity = max(1, item.quantity ?? 1)
            let unitPrice: Double
            if let unit = item.unit_price, unit.isFinite {
                unitPrice = unit
            } else if let total = item.total, total.isFinite {
                unitPrice = total / Double(quantity)
            } else {
                unitPrice = 0
            }
            return ReceiptItem(name: item.name, quantity: quantity, unitPrice: unitPrice)
        }

        return ReceiptModel(
            storeName: payload.store_name,
            total: payload.total,
            paymentMethod: (payload.payment_method ?? "other").replacingOccurrences(of: "_", with: " "),
            purchaseDate: purchaseDate,
            items: mappedItems,
            storeAddress: payload.store_address ?? "Address unavailable"
        )
    }
}
