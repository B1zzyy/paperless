import React from 'react';
import { Link } from 'react-router-dom';
import { format } from 'date-fns';
import { ChevronRight, Store } from 'lucide-react';
import { motion } from 'framer-motion';

export default function ReceiptCard({ receipt, index }) {
  const itemCount = receipt.items?.length || 0;

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.3 }}
    >
      <Link to={`/receipt/${receipt.id}`}>
        <div className="bg-card rounded-2xl p-4 border border-border hover:border-primary/20 transition-all duration-300 group">
          <div className="flex items-center gap-3.5">
            <div className="w-11 h-11 rounded-xl bg-accent flex items-center justify-center shrink-0">
              <Store className="w-5 h-5 text-accent-foreground" strokeWidth={1.8} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-sm text-foreground truncate pr-2">
                  {receipt.store_name}
                </h3>
                <span className="font-semibold text-sm text-foreground whitespace-nowrap">
                  ${receipt.total?.toFixed(2)}
                </span>
              </div>
              <div className="flex items-center justify-between mt-0.5">
                <p className="text-xs text-muted-foreground">
                  {itemCount} item{itemCount !== 1 ? 's' : ''} · {receipt.payment_method?.replace('_', ' ') || 'N/A'}
                </p>
                <p className="text-xs text-muted-foreground">
                  {receipt.purchase_date
                    ? format(new Date(receipt.purchase_date), 'MMM d, h:mm a')
                    : 'No date'}
                </p>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-muted-foreground/50 group-hover:text-primary transition-colors shrink-0" />
          </div>
        </div>
      </Link>
    </motion.div>
  );
}