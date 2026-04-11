import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { FlaskConical, Copy, Check } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { sampleReceipts, generateQRCodeURL } from '@/lib/qr-utils';

export default function TestQR() {
  const [selectedIdx, setSelectedIdx] = useState(0);
  const [copied, setCopied] = useState(false);

  const receipt = sampleReceipts[selectedIdx];
  const qrUrl = generateQRCodeURL(receipt, 280);
  const jsonStr = JSON.stringify(receipt, null, 2);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(JSON.stringify(receipt));
    setCopied(true);
    toast.success('QR data copied to clipboard');
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="max-w-lg mx-auto px-5 pt-14 pb-6">
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-6"
      >
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-widest mb-1">
          Testing
        </p>
        <h1 className="text-2xl font-bold text-foreground tracking-tight">
          Test QR Codes
        </h1>
      </motion.div>

      {/* Receipt selector */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-1">
        {sampleReceipts.map((r, i) => (
          <button
            key={i}
            onClick={() => setSelectedIdx(i)}
            className={`px-4 py-2 rounded-xl text-xs font-medium whitespace-nowrap transition-all ${
              selectedIdx === i
                ? 'bg-primary text-primary-foreground'
                : 'bg-secondary text-secondary-foreground hover:bg-secondary/80'
            }`}
          >
            {r.store_name}
          </button>
        ))}
      </div>

      {/* QR Code */}
      <motion.div
        key={selectedIdx}
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.3 }}
        className="bg-card rounded-2xl border border-border p-6 flex flex-col items-center"
      >
        <div className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center mb-4">
          <FlaskConical className="w-5 h-5 text-accent-foreground" />
        </div>
        <h2 className="font-semibold text-sm mb-1">{receipt.store_name}</h2>
        <p className="text-xs text-muted-foreground mb-5">
          ${receipt.total.toFixed(2)} · {receipt.items.length} items
        </p>

        <div className="bg-white rounded-xl p-4 mb-5">
          <img
            src={qrUrl}
            alt={`QR code for ${receipt.store_name}`}
            className="w-[200px] h-[200px]"
          />
        </div>

        <p className="text-xs text-muted-foreground text-center max-w-[260px] mb-4 leading-relaxed">
          Scan this QR code with the scanner page, or copy the data below and paste it manually.
        </p>

        <Button
          variant="outline"
          onClick={handleCopy}
          className="rounded-xl h-10 px-5 w-full"
        >
          {copied ? (
            <>
              <Check className="w-4 h-4 mr-2" />
              Copied!
            </>
          ) : (
            <>
              <Copy className="w-4 h-4 mr-2" />
              Copy QR Data
            </>
          )}
        </Button>
      </motion.div>

      {/* JSON preview */}
      <div className="mt-5">
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">
          QR Data Preview
        </p>
        <pre className="bg-secondary/50 rounded-xl p-4 text-xs text-muted-foreground overflow-x-auto leading-relaxed">
          {jsonStr}
        </pre>
      </div>
    </div>
  );
}