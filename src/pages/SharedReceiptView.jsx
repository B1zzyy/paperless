const db = globalThis.__B44_DB__ || { auth:{ isAuthenticated: async()=>false, me: async()=>null }, entities:new Proxy({}, { get:()=>({ filter:async()=>[], get:async()=>null, create:async()=>({}), update:async()=>({}), delete:async()=>({}) }) }), integrations:{ Core:{ UploadFile:async()=>({ file_url:'' }) } } };

import React from 'react';

import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { motion } from 'framer-motion';
import { Store, Calendar, CreditCard, MapPin, Receipt, Scissors } from 'lucide-react';
import { Separator } from '@/components/ui/separator';

const paymentLabels = {
  cash: 'Cash',
  credit_card: 'Credit Card',
  debit_card: 'Debit Card',
  mobile_pay: 'Mobile Pay',
  other: 'Other',
};

export default function SharedReceiptView() {
  const shareId = window.location.pathname.split('/split/')[1];

  const { data: shared, isLoading } = useQuery({
    queryKey: ['shared-receipt', shareId],
    queryFn: async () => {
      const list = await db.entities.SharedReceipt.filter({ id: shareId });
      return list[0];
    },
    enabled: !!shareId,
  });

  if (isLoading) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-background">
        <div className="w-6 h-6 border-2 border-muted border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  if (!shared) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-background">
        <p className="text-muted-foreground text-sm">This link is invalid or has expired.</p>
      </div>
    );
  }

  const receipt = shared.receipt_snapshot;
  const pct = shared.split_percent;
  const splitTotal = ((receipt.total || 0) * pct) / 100;

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-lg mx-auto px-5 pt-10 pb-10">
        {/* Header */}
        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="mb-6">
          <div className="flex items-center gap-2 mb-1">
            <Scissors className="w-3.5 h-3.5 text-primary" />
            <p className="text-xs font-medium text-primary uppercase tracking-widest">
              Split Receipt · Your {pct}%
            </p>
          </div>
          <p className="text-xs text-muted-foreground">
            Someone shared this receipt with you. Below is your portion.
          </p>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <div className="bg-card rounded-2xl border border-border overflow-hidden">
            {/* Store info */}
            <div className="p-5 pb-4">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-xl bg-accent flex items-center justify-center">
                  <Store className="w-6 h-6 text-accent-foreground" strokeWidth={1.8} />
                </div>
                <div>
                  <h1 className="text-lg font-bold">{receipt.store_name}</h1>
                  {receipt.receipt_id && (
                    <p className="text-xs text-muted-foreground font-mono">{receipt.receipt_id}</p>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                {receipt.purchase_date && (
                  <div className="flex items-center gap-2">
                    <Calendar className="w-3.5 h-3.5 text-muted-foreground" />
                    <span className="text-xs text-muted-foreground">
                      {format(new Date(receipt.purchase_date), 'MMM d, yyyy · h:mm a')}
                    </span>
                  </div>
                )}
                {receipt.payment_method && (
                  <div className="flex items-center gap-2">
                    <CreditCard className="w-3.5 h-3.5 text-muted-foreground" />
                    <span className="text-xs text-muted-foreground">
                      {paymentLabels[receipt.payment_method] || receipt.payment_method}
                    </span>
                  </div>
                )}
                {receipt.store_address && (
                  <div className="flex items-start gap-2 col-span-2">
                    <MapPin className="w-3.5 h-3.5 text-muted-foreground mt-0.5" />
                    <span className="text-xs text-muted-foreground">{receipt.store_address}</span>
                  </div>
                )}
              </div>
            </div>

            <Separator />

            {/* Items */}
            <div className="p-5">
              <div className="flex items-center gap-2 mb-3">
                <Receipt className="w-3.5 h-3.5 text-muted-foreground" />
                <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Items</span>
              </div>
              <div className="space-y-3">
                {receipt.items?.map((item, i) => {
                  const splitItemTotal = ((item.total || 0) * pct) / 100;
                  return (
                    <div key={i} className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate pr-3">{item.name}</p>
                        {item.quantity > 1 && (
                          <p className="text-xs text-muted-foreground">
                            {item.quantity} × ${item.unit_price?.toFixed(2)}
                          </p>
                        )}
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-muted-foreground line-through">${item.total?.toFixed(2)}</p>
                        <p className="text-sm font-semibold text-primary">${splitItemTotal.toFixed(2)}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <Separator />

            {/* Totals */}
            <div className="p-5 space-y-2">
              {receipt.subtotal !== undefined && (
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>Subtotal</span>
                  <div className="text-right">
                    <span className="line-through mr-2">${receipt.subtotal?.toFixed(2)}</span>
                    <span className="text-foreground">${((receipt.subtotal * pct) / 100).toFixed(2)}</span>
                  </div>
                </div>
              )}
              {receipt.tax !== undefined && (
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>Tax</span>
                  <div className="text-right">
                    <span className="line-through mr-2">${receipt.tax?.toFixed(2)}</span>
                    <span className="text-foreground">${((receipt.tax * pct) / 100).toFixed(2)}</span>
                  </div>
                </div>
              )}
              <Separator className="my-2" />
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-base font-bold">Your Total</p>
                  <p className="text-xs text-muted-foreground">{pct}% of ${receipt.total?.toFixed(2)}</p>
                </div>
                <span className="text-2xl font-bold text-primary">${splitTotal.toFixed(2)}</span>
              </div>
            </div>
          </div>

          <p className="text-center text-xs text-muted-foreground mt-6">
            Shared via Receipt Scanner
          </p>
        </motion.div>
      </div>
    </div>
  );
}