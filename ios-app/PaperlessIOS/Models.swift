import Foundation

struct ReceiptItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let quantity: Int
    let unitPrice: Double

    var total: Double { Double(quantity) * unitPrice }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case unitPrice
        case total
    }

    init(id: UUID = UUID(), name: String, quantity: Int, unitPrice: Double) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        quantity = max(1, try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1)

        if let decodedUnitPrice = try container.decodeIfPresent(Double.self, forKey: .unitPrice) {
            unitPrice = decodedUnitPrice
        } else if let decodedTotal = try container.decodeIfPresent(Double.self, forKey: .total) {
            unitPrice = decodedTotal / Double(quantity)
        } else {
            unitPrice = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
        try container.encode(total, forKey: .total)
    }
}

struct ReceiptModel: Identifiable, Hashable, Codable {
    let id: UUID
    let storeName: String
    let total: Double
    let subtotal: Double?
    let tax: Double?
    let paymentMethod: String
    let purchaseDate: Date
    let items: [ReceiptItem]
    let storeAddress: String

    init(
        id: UUID = UUID(),
        storeName: String,
        total: Double,
        subtotal: Double? = nil,
        tax: Double? = nil,
        paymentMethod: String,
        purchaseDate: Date,
        items: [ReceiptItem],
        storeAddress: String
    ) {
        self.id = id
        self.storeName = storeName
        self.total = total
        self.subtotal = subtotal
        self.tax = tax
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
    let subtotal: Double?
    let tax: Double?
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
        let computedSubtotal = mappedItems.reduce(0) { $0 + $1.total }
        let resolvedSubtotal = (payload.subtotal?.isFinite == true ? payload.subtotal! : computedSubtotal)
        let resolvedTax = (payload.tax?.isFinite == true ? payload.tax! : max(0, payload.total - resolvedSubtotal))

        return ReceiptModel(
            storeName: payload.store_name,
            total: payload.total,
            subtotal: resolvedSubtotal,
            tax: resolvedTax,
            paymentMethod: (payload.payment_method ?? "other").replacingOccurrences(of: "_", with: " "),
            purchaseDate: purchaseDate,
            items: mappedItems,
            storeAddress: payload.store_address ?? "Address unavailable"
        )
    }
}

struct ReceiptSharePayload: Codable {
    let version: Int
    let splitPercent: Double
    let receipt: ReceiptModel
}

enum ReceiptShareLink {
    private static let webShareBaseURL = "https://paperless-webapp.vercel.app/share"

    static func url(for receipt: ReceiptModel, splitPercent: Double) -> URL? {
        let clamped = max(1, min(100, splitPercent))
        let payload = ReceiptSharePayload(version: 1, splitPercent: clamped, receipt: receipt)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard
            let data = try? encoder.encode(payload),
            let base64 = data.base64EncodedString().toBase64URL()
        else {
            return nil
        }

        guard var components = URLComponents(string: webShareBaseURL) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "payload", value: base64)]
        return components.url
    }

    static func parse(_ url: URL) -> ReceiptSharePayload? {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let payloadValue = components.queryItems?.first(where: { $0.name == "payload" })?.value,
            let normalized = payloadValue.fromBase64URL(),
            let data = Data(base64Encoded: normalized)
        else {
            return nil
        }

        let isCustomScheme = (url.scheme?.lowercased() == "paperless" && url.host?.lowercased() == "share")
        let isWebShare = url.path.lowercased() == "/share"
        guard isCustomScheme || isWebShare else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ReceiptSharePayload.self, from: data)
    }
}

private extension String {
    func toBase64URL() -> String? {
        replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    func fromBase64URL() -> String? {
        var value = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = value.count % 4
        if remainder > 0 {
            value += String(repeating: "=", count: 4 - remainder)
        }
        return value
    }
}
