const db = globalThis.__B44_DB__ || { auth:{ isAuthenticated: async()=>false, me: async()=>null }, entities:new Proxy({}, { get:()=>({ filter:async()=>[], get:async()=>null, create:async()=>({}), update:async()=>({}), delete:async()=>({}) }) }), integrations:{ Core:{ UploadFile:async()=>({ file_url:'' }) } } };

import React, { useState } from 'react';

import { motion, AnimatePresence } from 'framer-motion';
import { X, Copy, Check, Link } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { toast } from 'sonner';

const PRESETS = [25, 33, 50, 75];

export default function ShareSheet({ receipt, onClose }) {
  const [splitPercent, setSplitPercent] = useState(null);
  const [customValue, setCustomValue] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [generatedLink, setGeneratedLink] = useState(null);
  const [copied, setCopied] = useState(false);

  const activeSplit = customValue ? parseFloat(customValue) : splitPercent;
  const hasSplit = activeSplit !== null && activeSplit !== undefined && !isNaN(activeSplit);
  const splitTotal = ((receipt.total || 0) * activeSplit) / 100;

  const handleGenerate = async () => {
    setIsGenerating(true);
    const shared = await db.entities.SharedReceipt.create({
      receipt_id: receipt.id,
      split_percent: hasSplit ? activeSplit : 100,
      receipt_snapshot: receipt,
    });
    const link = `${window.location.origin}/split/${shared.id}`;
    setGeneratedLink(link);
    setIsGenerating(false);
  };

  const handleCopy = async () => {
    await navigator.clipboard.writeText(generatedLink);
    setCopied(true);
    toast.success('Link copied to clipboard');
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 z-[55] flex items-end justify-center"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      >
        {/* Backdrop */}
        <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

        {/* Sheet */}
        <motion.div
          className="relative w-full max-w-lg bg-card rounded-t-3xl border-t border-border p-6 pb-28 z-[60]"
          initial={{ y: '100%' }}
          animate={{ y: 0 }}
          exit={{ y: '100%' }}
          transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        >
          {/* Handle */}
          <div className="w-10 h-1 bg-border rounded-full mx-auto mb-5" />

          <div className="flex items-center justify-between mb-5">
            <h2 className="text-base font-semibold">Share</h2>
            <button onClick={onClose} className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center">
              <X className="w-4 h-4 text-muted-foreground" />
            </button>
          </div>

          {!generatedLink ? (
            <>
              <p className="text-sm text-muted-foreground mb-4">
                Choose what percentage to share with someone.
              </p>

              {/* Preset buttons */}
              <div className="grid grid-cols-4 gap-2 mb-4">
                {PRESETS.map((p) => (
                  <button
                    key={p}
                    onClick={() => { setSplitPercent(p); setCustomValue(''); }}
                    className={`py-3 rounded-xl text-sm font-semibold transition-all ${
                      !customValue && splitPercent === p
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-secondary text-secondary-foreground hover:bg-secondary/70'
                    }`}
                  >
                    {p}%
                  </button>
                ))}
              </div>

              {/* Custom input */}
              <div className="flex items-center gap-2 mb-5">
                <Input
                  type="number"
                  min="1"
                  max="100"
                  placeholder="Custom %"
                  value={customValue}
                  onChange={(e) => setCustomValue(e.target.value)}
                  className="rounded-xl h-11 bg-secondary/50 border-0"
                />
                <span className="text-sm text-muted-foreground font-medium">%</span>
              </div>

              {/* Summary */}
              {hasSplit && (
              <div className="bg-accent/50 rounded-xl px-4 py-3 mb-5 flex justify-between items-center">
                <span className="text-sm text-muted-foreground">Their share ({activeSplit}%)</span>
                <span className="text-base font-bold text-foreground">${splitTotal.toFixed(2)}</span>
              </div>
              )}

              <Button
                className="w-full h-12 rounded-xl text-base font-medium"
                onClick={handleGenerate}
                disabled={isGenerating || (hasSplit && (activeSplit <= 0 || activeSplit > 100))}
              >
                {isGenerating ? (
                  <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                ) : (
                  <><Link className="w-4 h-4 mr-2" />Generate Link</>
                )}
              </Button>
            </>
          ) : (
            <div className="flex flex-col items-center text-center">
              <div className="w-14 h-14 rounded-2xl bg-accent flex items-center justify-center mb-4">
                <Link className="w-6 h-6 text-accent-foreground" />
              </div>
              <p className="text-sm font-medium mb-1">Link ready!</p>
              <p className="text-xs text-muted-foreground mb-5">
                Share this with the person paying {activeSplit}% (${splitTotal.toFixed(2)})
              </p>
              <div className="w-full bg-secondary/60 rounded-xl px-4 py-3 text-xs text-muted-foreground font-mono truncate mb-4">
                {generatedLink}
              </div>
              <Button className="w-full h-12 rounded-xl text-base font-medium" onClick={handleCopy}>
                {copied ? <><Check className="w-4 h-4 mr-2" />Copied!</> : <><Copy className="w-4 h-4 mr-2" />Copy Link</>}
              </Button>
              <button
                onClick={() => { setGeneratedLink(null); }}
                className="mt-3 text-xs text-muted-foreground hover:text-foreground transition-colors"
              >
                Generate another split
              </button>
            </div>
          )}
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}