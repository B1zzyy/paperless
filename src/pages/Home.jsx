const db = globalThis.__B44_DB__ || { auth:{ isAuthenticated: async()=>false, me: async()=>null }, entities:new Proxy({}, { get:()=>({ filter:async()=>[], get:async()=>null, create:async()=>({}), update:async()=>({}), delete:async()=>({}) }) }), integrations:{ Core:{ UploadFile:async()=>({ file_url:'' }) } } };

import React, { useState } from 'react';

import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Wallet } from 'lucide-react';
import ReceiptCard from '@/components/receipts/ReceiptCard';
import EmptyState from '@/components/receipts/EmptyState';
import { normalizeEntityList } from '@/lib/entity-list';

export default function Home() {
  const [showAll, setShowAll] = useState(false);
  const { data: receipts = [], isLoading } = useQuery({
    queryKey: ['receipts'],
    queryFn: async () => {
      const raw = await db.entities.Receipt.list('-purchase_date');
      return normalizeEntityList(raw);
    },
  });

  const totalSpent = receipts.reduce((sum, r) => sum + (r.total || 0), 0);
  const visibleReceipts = showAll ? receipts : receipts.slice(0, 5);

  return (
    <div className="max-w-lg mx-auto px-5 pt-14 pb-28">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-8"
      >
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-widest mb-1">
          Your Receipts
        </p>
        <h1 className="text-2xl font-bold text-foreground tracking-tight">
          Expenses
        </h1>
      </motion.div>

      {/* Summary card */}
      {receipts.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-primary text-primary-foreground rounded-2xl p-5 mb-8"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-primary-foreground/70 uppercase tracking-wider">
                Total Spent
              </p>
              <p className="text-3xl font-bold mt-1 tracking-tight">
                ${totalSpent.toFixed(2)}
              </p>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-primary-foreground/15 flex items-center justify-center">
              <Wallet className="w-6 h-6 text-primary-foreground" strokeWidth={1.8} />
            </div>
          </div>
          <p className="text-xs text-primary-foreground/60 mt-3">
            {receipts.length} receipt{receipts.length !== 1 ? 's' : ''} saved
          </p>
        </motion.div>
      )}

      {/* Loading */}
      {isLoading && (
        <div className="flex justify-center py-20">
          <div className="w-6 h-6 border-2 border-muted border-t-primary rounded-full animate-spin" />
        </div>
      )}

      {/* Receipts list */}
      {!isLoading && receipts.length === 0 && <EmptyState />}

      {!isLoading && receipts.length > 0 && (
        <div className="bg-secondary/40 rounded-2xl p-3">
          <div className="space-y-2">
            {visibleReceipts.map((receipt, i) => (
              <ReceiptCard key={receipt.id} receipt={receipt} index={i} />
            ))}
          </div>
          {receipts.length > 5 && (
            <button
              onClick={() => setShowAll(!showAll)}
              className="w-full pt-3 pb-1 text-xs font-medium text-primary flex items-center justify-center gap-1.5 hover:text-primary/70 transition-colors"
            >
              {showAll ? (
                <><span>Show less</span><span className="text-base leading-none">↑</span></>
              ) : (
                <><span>Show all {receipts.length} receipts</span><span className="text-base leading-none">↓</span></>
              )}
            </button>
          )}
        </div>
      )}
    </div>
  );
}