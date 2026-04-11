const db = globalThis.__B44_DB__ || { auth:{ isAuthenticated: async()=>false, me: async()=>null }, entities:new Proxy({}, { get:()=>({ filter:async()=>[], get:async()=>null, create:async()=>({}), update:async()=>({}), delete:async()=>({}) }) }), integrations:{ Core:{ UploadFile:async()=>({ file_url:'' }) } } };

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { motion } from 'framer-motion';
import { ArrowLeft, Store, Calendar, CreditCard, MapPin, Receipt, Share2 } from 'lucide-react';
import ShareSheet from '@/components/receipts/ShareSheet';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';

const paymentLabels = {
  cash: 'Cash',
  credit_card: 'Credit Card',
  debit_card: 'Debit Card',
  mobile_pay: 'Mobile Pay',
  other: 'Other',
};

export default function ReceiptDetail() {
  const id = window.location.pathname.split('/receipt/')[1];
  const [showShare, setShowShare] = useState(false);
  const navigate = useNavigate();

  const { data: receipt, isLoading } = useQuery({
    queryKey: ['receipt', id],
    queryFn: async () => {
      const list = await db.entities.Receipt.filter({ id });
      return list[0];
    },
    enabled: !!id,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="w-6 h-6 border-2 border-muted border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  if (!receipt) {
    return (
      <div className="max-w-lg mx-auto px-5 pt-14 text-center">
        <p className="text-muted-foreground">Receipt not found.</p>
        <Button variant="ghost" onClick={() => navigate('/')} className="mt-4">
          Go back
        </Button>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto px-5 pt-10 pb-6">
      {/* Back button */}
      <div className="flex items-center justify-between mb-4">
        <Button variant="ghost" size="icon" onClick={() => navigate('/')} className="rounded-xl h-10 w-10">
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <Button variant="ghost" size="icon" onClick={() => setShowShare(true)} className="rounded-xl h-10 w-10">
          <Share2 className="w-5 h-5" />
        </Button>
      </div>
      {showShare && <ShareSheet receipt={receipt} onClose={() => setShowShare(false)} />}

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
      >
        {/* Receipt header */}
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
              <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Items
              </span>
            </div>
            <div className="space-y-2.5">
              {receipt.items?.map((item, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate pr-3">{item.name}</p>
                    {item.quantity > 1 && (
                      <p className="text-xs text-muted-foreground">
                        {item.quantity} × ${item.unit_price?.toFixed(2)}
                      </p>
                    )}
                  </div>
                  <span className="text-sm font-medium whitespace-nowrap">
                    ${item.total?.toFixed(2)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <Separator />

          {/* Totals */}
          <div className="p-5 space-y-2">
            {receipt.subtotal !== undefined && (
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>Subtotal</span>
                <span>${receipt.subtotal?.toFixed(2)}</span>
              </div>
            )}
            {receipt.tax !== undefined && (
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>Tax</span>
                <span>${receipt.tax?.toFixed(2)}</span>
              </div>
            )}
            <Separator className="my-2" />
            <div className="flex justify-between text-base font-bold">
              <span>Total</span>
              <span>${receipt.total?.toFixed(2)}</span>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}