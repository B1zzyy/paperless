// Sample receipt data for testing
export const sampleReceipts = [
  {
    receipt_id: "RCP-2026-001",
    store_name: "Whole Foods Market",
    store_address: "123 Main St, San Francisco, CA 94102",
    purchase_date: "2026-04-06T10:23:00Z",
    items: [
      { name: "Organic Avocados (3)", quantity: 1, unit_price: 4.99, total: 4.99 },
      { name: "Sourdough Bread", quantity: 1, unit_price: 5.49, total: 5.49 },
      { name: "Oat Milk", quantity: 2, unit_price: 3.99, total: 7.98 },
      { name: "Free Range Eggs", quantity: 1, unit_price: 6.29, total: 6.29 },
      { name: "Mixed Greens Salad", quantity: 1, unit_price: 4.49, total: 4.49 }
    ],
    subtotal: 29.24,
    tax: 2.63,
    total: 31.87,
    currency: "USD",
    payment_method: "credit_card"
  },
  {
    receipt_id: "RCP-2026-002",
    store_name: "Blue Bottle Coffee",
    store_address: "456 Market St, San Francisco, CA 94105",
    purchase_date: "2026-04-06T08:15:00Z",
    items: [
      { name: "Cortado", quantity: 1, unit_price: 5.50, total: 5.50 },
      { name: "Almond Croissant", quantity: 1, unit_price: 4.75, total: 4.75 }
    ],
    subtotal: 10.25,
    tax: 0.92,
    total: 11.17,
    currency: "USD",
    payment_method: "mobile_pay"
  },
  {
    receipt_id: "RCP-2026-003",
    store_name: "Target",
    store_address: "789 Mission St, San Francisco, CA 94103",
    purchase_date: "2026-04-05T16:42:00Z",
    items: [
      { name: "USB-C Cable", quantity: 2, unit_price: 12.99, total: 25.98 },
      { name: "Wireless Mouse", quantity: 1, unit_price: 24.99, total: 24.99 },
      { name: "Notebook 3-Pack", quantity: 1, unit_price: 8.99, total: 8.99 },
      { name: "Hand Sanitizer", quantity: 3, unit_price: 2.99, total: 8.97 }
    ],
    subtotal: 68.93,
    tax: 6.20,
    total: 75.13,
    currency: "USD",
    payment_method: "debit_card"
  }
];

export function parseQRData(rawData) {
  const trimmed = typeof rawData === 'string' ? rawData.trim() : '';
  try {
    const data = JSON.parse(trimmed);
    const total = data.total;
    const hasTotal =
      total !== undefined &&
      total !== null &&
      total !== '' &&
      !Number.isNaN(Number(total));
    if (data.store_name && hasTotal) {
      return { success: true, data };
    }
  } catch {}

  return { success: false, error: 'Invalid QR code format. Expected receipt JSON data.' };
}

// Generate QR code URL using a free QR API
export function generateQRCodeURL(data, size = 300) {
  const jsonStr = JSON.stringify(data);
  const encoded = encodeURIComponent(jsonStr);
  return `https://api.qrserver.com/v1/create-qr-code/?size=${size}x${size}&data=${encoded}&margin=10`;
}