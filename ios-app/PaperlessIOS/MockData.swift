import Foundation

enum MockData {
    static let receipts: [ReceiptModel] = [
        ReceiptModel(
            storeName: "Fresh Mart",
            total: 42.75,
            paymentMethod: "credit card",
            purchaseDate: Date().addingTimeInterval(-3600 * 5),
            items: [
                ReceiptItem(name: "Organic Milk", quantity: 1, unitPrice: 5.99),
                ReceiptItem(name: "Strawberries", quantity: 2, unitPrice: 4.25),
                ReceiptItem(name: "Avocados", quantity: 3, unitPrice: 2.49),
                ReceiptItem(name: "Sourdough", quantity: 1, unitPrice: 7.80)
            ],
            storeAddress: "123 Market Street, San Francisco, CA"
        ),
        ReceiptModel(
            storeName: "City Pharmacy",
            total: 18.40,
            paymentMethod: "mobile pay",
            purchaseDate: Date().addingTimeInterval(-3600 * 28),
            items: [
                ReceiptItem(name: "Vitamin C", quantity: 1, unitPrice: 12.40),
                ReceiptItem(name: "Hand Sanitizer", quantity: 1, unitPrice: 6.00)
            ],
            storeAddress: "88 Mission Street, San Francisco, CA"
        ),
        ReceiptModel(
            storeName: "Coffee House",
            total: 9.85,
            paymentMethod: "debit card",
            purchaseDate: Date().addingTimeInterval(-3600 * 50),
            items: [
                ReceiptItem(name: "Latte", quantity: 1, unitPrice: 5.25),
                ReceiptItem(name: "Croissant", quantity: 1, unitPrice: 4.60)
            ],
            storeAddress: "250 Howard Street, San Francisco, CA"
        ),
        ReceiptModel(
            storeName: "Green Grocer",
            total: 26.10,
            paymentMethod: "credit card",
            purchaseDate: Date().addingTimeInterval(-3600 * 70),
            items: [
                ReceiptItem(name: "Bananas", quantity: 6, unitPrice: 0.49),
                ReceiptItem(name: "Spinach", quantity: 2, unitPrice: 3.10),
                ReceiptItem(name: "Almonds", quantity: 1, unitPrice: 8.75)
            ],
            storeAddress: "402 Valencia Street, San Francisco, CA"
        ),
        ReceiptModel(
            storeName: "Book Nook",
            total: 31.50,
            paymentMethod: "mobile pay",
            purchaseDate: Date().addingTimeInterval(-3600 * 96),
            items: [
                ReceiptItem(name: "Notebook", quantity: 2, unitPrice: 6.50),
                ReceiptItem(name: "Gel Pens", quantity: 1, unitPrice: 5.00),
                ReceiptItem(name: "Planner", quantity: 1, unitPrice: 13.50)
            ],
            storeAddress: "17 Market Square, San Francisco, CA"
        )
    ]
}
