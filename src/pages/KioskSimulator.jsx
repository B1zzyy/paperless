import React, { useState } from 'react';

import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trash2, ShoppingCart, CheckCircle2, Monitor } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

const DEFAULT_ITEMS = [
  { name: 'Whole Milk 2L', quantity: 1, unit_price: 2.49, total: 2.49 },
  { name: 'Sourdough Bread', quantity: 1, unit_price: 3.99, total: 3.99 },
];

const STAGE_CHECKOUT = 'checkout';
const STAGE_PAYING = 'paying';
const STAGE_QR = 'qr';

export default function KioskSimulator() {
  const [stage, setStage] = useState(STAGE_CHECKOUT);
  const [storeName, setStoreName] = useState('FreshMart Supermarket');
  const [items, setItems] = useState(DEFAULT_ITEMS);
  const [newItem, setNewItem] = useState({ name: '', quantity: 1, unit_price: '' });
  const [receipt, setReceipt] = useState(null);

  const subtotal = items.reduce((s, i) => s + i.total, 0);
  const tax = parseFloat((subtotal * 0.08).toFixed(2));
  const total = parseFloat((subtotal + tax).toFixed(2));

  const addItem = () => {
    if (!newItem.name || !newItem.unit_price) return;
    const price = parseFloat(newItem.unit_price);
    const qty = parseInt(newItem.quantity) || 1;
    setItems([...items, { name: newItem.name, quantity: qty, unit_price: price, total: parseFloat((price * qty).toFixed(2)) }]);
    setNewItem({ name: '', quantity: 1, unit_price: '' });
  };

  const removeItem = (idx) => setItems(items.filter((_, i) => i !== idx));

  const handlePay = async () => {
    setStage(STAGE_PAYING);
    // Simulate payment processing delay
    await new Promise(r => setTimeout(r, 2000));
    // Kiosk only builds a QR payload — does not save to the user’s account (customer scans to import).
    const receiptPayload = {
      store_name: storeName,
      purchase_date: new Date().toISOString(),
      items,
      subtotal,
      tax,
      total,
      payment_method: 'credit_card',
      receipt_id: `SIM-${Date.now()}`,
    };
    setReceipt(receiptPayload);
    setStage(STAGE_QR);
  };

  const reset = () => {
    setStage(STAGE_CHECKOUT);
    setReceipt(null);
    setItems(DEFAULT_ITEMS);
  };

  const qrData = receipt ? JSON.stringify({
    store_name: receipt.store_name,
    store_address: receipt.store_address,
    purchase_date: receipt.purchase_date,
    items: receipt.items,
    subtotal: receipt.subtotal,
    tax: receipt.tax,
    total: receipt.total,
    payment_method: receipt.payment_method,
    receipt_id: receipt.receipt_id,
  }) : '';
  const qrUrl = receipt ? `https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${encodeURIComponent(qrData)}&margin=10` : '';

  return (
    <div className="max-w-lg mx-auto px-5 pt-14 pb-10">
      {/* Header */}
      <div className="flex items-center gap-2 mb-1">
        <Monitor className="w-4 h-4 text-primary" />
        <p className="text-xs font-medium text-primary uppercase tracking-widest">Kiosk Simulator</p>
      </div>
      <h1 className="text-2xl font-bold text-foreground tracking-tight mb-6">Self-Checkout</h1>

      <AnimatePresence mode="wait">

        {/* STAGE: Checkout */}
        {stage === STAGE_CHECKOUT && (
          <motion.div key="checkout" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
            {/* Store name */}
            <div className="mb-4">
              <p className="text-xs text-muted-foreground mb-1.5 font-medium">Store Name</p>
              <Input
                value={storeName}
                onChange={e => setStoreName(e.target.value)}
                className="rounded-xl h-11 bg-secondary/50 border-0"
              />
            </div>

            {/* Items */}
            <div className="bg-card rounded-2xl border border-border overflow-hidden mb-4">
              <div className="flex items-center gap-2 px-4 py-3 border-b border-border">
                <ShoppingCart className="w-4 h-4 text-muted-foreground" />
                <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Basket</span>
              </div>
              <div className="divide-y divide-border">
                {items.map((item, i) => (
                  <div key={i} className="flex items-center justify-between px-4 py-3">
                    <div>
                      <p className="text-sm font-medium">{item.name}</p>
                      {item.quantity > 1 && <p className="text-xs text-muted-foreground">{item.quantity} × ${item.unit_price.toFixed(2)}</p>}
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-sm font-semibold">${item.total.toFixed(2)}</span>
                      <button onClick={() => removeItem(i)} className="text-muted-foreground hover:text-destructive transition-colors">
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
              {/* Add item row */}
              <div className="px-4 py-3 border-t border-border bg-secondary/30 flex gap-2">
                <Input
                  placeholder="Item name"
                  value={newItem.name}
                  onChange={e => setNewItem({ ...newItem, name: e.target.value })}
                  className="rounded-lg h-9 text-xs bg-card border-0 flex-1"
                />
                <Input
                  type="number"
                  placeholder="Qty"
                  value={newItem.quantity}
                  onChange={e => setNewItem({ ...newItem, quantity: e.target.value })}
                  className="rounded-lg h-9 text-xs bg-card border-0 w-14"
                />
                <Input
                  type="number"
                  placeholder="$"
                  value={newItem.unit_price}
                  onChange={e => setNewItem({ ...newItem, unit_price: e.target.value })}
                  className="rounded-lg h-9 text-xs bg-card border-0 w-20"
                />
                <Button size="icon" onClick={addItem} className="h-9 w-9 rounded-lg shrink-0">
                  <Plus className="w-4 h-4" />
                </Button>
              </div>
            </div>

            {/* Totals */}
            <div className="bg-card rounded-2xl border border-border p-4 mb-6 space-y-1.5">
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>Subtotal</span><span>${subtotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>Tax (8%)</span><span>${tax.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-base font-bold pt-1 border-t border-border mt-1">
                <span>Total</span><span>${total.toFixed(2)}</span>
              </div>
            </div>

            <Button
              className="w-full h-14 rounded-2xl text-base font-semibold"
              onClick={handlePay}
              disabled={items.length === 0}
            >
              Pay ${total.toFixed(2)}
            </Button>
          </motion.div>
        )}

        {/* STAGE: Processing payment */}
        {stage === STAGE_PAYING && (
          <motion.div key="paying" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }}
            className="flex flex-col items-center justify-center py-24 text-center"
          >
            <div className="w-16 h-16 rounded-3xl bg-accent flex items-center justify-center mb-5">
              <div className="w-7 h-7 border-2 border-accent-foreground/30 border-t-accent-foreground rounded-full animate-spin" />
            </div>
            <h2 className="text-lg font-semibold mb-1">Processing Payment</h2>
            <p className="text-sm text-muted-foreground">Please tap or insert your card…</p>
          </motion.div>
        )}

        {/* STAGE: QR Code display */}
        {stage === STAGE_QR && receipt && (
          <motion.div key="qr" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }}
            className="flex flex-col items-center text-center"
          >
            <div className="w-14 h-14 rounded-2xl bg-primary flex items-center justify-center mb-4">
              <CheckCircle2 className="w-7 h-7 text-primary-foreground" />
            </div>
            <h2 className="text-xl font-bold mb-1">Payment Successful!</h2>
            <p className="text-sm text-muted-foreground mb-6">
              Scan the QR code below to save your digital receipt.
            </p>

            {/* Kiosk-style QR display */}
            <div className="bg-card rounded-3xl border border-border p-8 w-full mb-6 flex flex-col items-center">
              <div className="bg-white rounded-2xl p-4 mb-4 shadow-sm">
                <img src={qrUrl} alt="Receipt QR" className="w-[200px] h-[200px]" />
              </div>
              <p className="text-xs text-muted-foreground font-medium uppercase tracking-wider mb-1">
                {storeName}
              </p>
              <p className="text-2xl font-bold">${total.toFixed(2)}</p>
              <p className="text-xs text-muted-foreground mt-1">
                {items.length} item{items.length !== 1 ? 's' : ''}
              </p>
            </div>

            <p className="text-xs text-muted-foreground mb-6">
              Point your phone camera at the QR code — no app download required.
            </p>

            <Button variant="outline" onClick={reset} className="rounded-xl h-11 px-8">
              Start New Transaction
            </Button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}