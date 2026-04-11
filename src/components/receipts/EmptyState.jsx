import React from 'react';
import { Link } from 'react-router-dom';
import { ScanLine } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { motion } from 'framer-motion';

export default function EmptyState() {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.4 }}
      className="flex flex-col items-center justify-center py-20 px-6 text-center"
    >
      <div className="w-20 h-20 rounded-3xl bg-accent flex items-center justify-center mb-6">
        <ScanLine className="w-9 h-9 text-accent-foreground" strokeWidth={1.5} />
      </div>
      <h2 className="text-lg font-semibold text-foreground mb-1.5">No receipts yet</h2>
      <p className="text-sm text-muted-foreground max-w-[240px] mb-6 leading-relaxed">
        Scan a QR code at checkout to save your first digital receipt.
      </p>
      <Link to="/scan">
        <Button className="rounded-xl px-6 h-11 font-medium">
          <ScanLine className="w-4 h-4 mr-2" />
          Scan QR Code
        </Button>
      </Link>
    </motion.div>
  );
}