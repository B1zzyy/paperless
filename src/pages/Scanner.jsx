const db = globalThis.__B44_DB__ || { auth:{ isAuthenticated: async()=>false, me: async()=>null }, entities:new Proxy({}, { get:()=>({ filter:async()=>[], get:async()=>null, create:async()=>({}), update:async()=>({}), delete:async()=>({}) }) }), integrations:{ Core:{ UploadFile:async()=>({ file_url:'' }) } } };

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { toast } from 'sonner';
import QRScanner from '@/components/scanner/QRScanner';
import ManualInput from '@/components/scanner/ManualInput';
import { parseQRData } from '@/lib/qr-utils';

export default function Scanner() {
  const [isProcessing, setIsProcessing] = useState(false);
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const handleQRData = async (rawData) => {
    if (isProcessing) return;

    const result = parseQRData(rawData);
    if (!result.success) {
      toast.error(result.error);
      return;
    }

    setIsProcessing(true);
    const receiptData = result.data;

    const created = await db.entities.Receipt.create(receiptData);
    queryClient.invalidateQueries({ queryKey: ['receipts'] });
    setIsProcessing(false);

    toast.success(`Added to ${receiptData.store_name}`, {
      description: `$${receiptData.total?.toFixed(2)} · ${receiptData.items?.length || 0} items`,
      duration: 3000,
    });

    setTimeout(() => navigate(`/receipt/${created.id}`), 800);
  };

  return (
    <div className="max-w-lg mx-auto px-5 pt-14 pb-6">
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-6"
      >
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-widest mb-1">
          Digital Receipt
        </p>
        <h1 className="text-2xl font-bold text-foreground tracking-tight">
          Scan QR
        </h1>
      </motion.div>

      <QRScanner onScan={handleQRData} isProcessing={isProcessing} />
      <ManualInput onSubmit={handleQRData} isProcessing={isProcessing} />

    </div>
  );
}