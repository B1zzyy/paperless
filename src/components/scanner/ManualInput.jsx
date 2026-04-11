import React, { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Keyboard } from 'lucide-react';

export default function ManualInput({ onSubmit, isProcessing }) {
  const [value, setValue] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (value.trim()) {
      onSubmit(value.trim());
      setValue('');
    }
  };

  return (
    <div className="mt-6 px-1">
      <div className="flex items-center gap-2 mb-3">
        <Keyboard className="w-4 h-4 text-muted-foreground" />
        <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
          Or paste QR data manually
        </span>
      </div>
      <form onSubmit={handleSubmit} className="flex gap-2">
        <Input
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="Paste QR code content..."
          className="rounded-xl h-11 bg-secondary/50 border-0 text-sm"
          disabled={isProcessing}
        />
        <Button
          type="submit"
          disabled={!value.trim() || isProcessing}
          className="rounded-xl h-11 px-5 shrink-0"
        >
          Add
        </Button>
      </form>
    </div>
  );
}