import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { InputOTP, InputOTPGroup, InputOTPSlot } from '@/components/ui/input-otp';
import { getSupabase } from '@/lib/supabase-client';
import { isSupabaseMode } from '@/lib/supabase-config';

export default function Login() {
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState('email');
  const [status, setStatus] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const next = params.get('next') || '/';

  const supabase = getSupabase();

  const sendCode = async (e) => {
    e?.preventDefault();
    if (!supabase || !email.trim()) return;
    setBusy(true);
    setStatus('');
    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: {
        shouldCreateUser: true,
      },
    });
    setBusy(false);
    if (error) {
      setStatus(error.message);
      return;
    }
    setStep('code');
    setStatus('Enter the 8-digit code from your email.');
  };

  const verifyCode = async (e) => {
    e?.preventDefault();
    if (!supabase || otp.length !== 8) return;
    setBusy(true);
    setStatus('');
    const { data, error } = await supabase.auth.verifyOtp({
      email: email.trim(),
      token: otp.replace(/\s/g, ''),
      type: 'email',
    });
    setBusy(false);
    if (error) {
      setStatus(error.message);
      return;
    }
    if (data.session) {
      const dest = next.startsWith('/') ? next : '/';
      navigate(dest, { replace: true });
    }
  };

  if (!isSupabaseMode()) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6 bg-background">
        <p className="text-muted-foreground text-sm text-center max-w-sm">
          This build is not using Supabase. Set <code className="text-xs">VITE_USE_SUPABASE=true</code> in{' '}
          <code className="text-xs">.env.local</code>.
        </p>
      </div>
    );
  }

  if (!supabase) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6 bg-background">
        <p className="text-destructive text-sm">Supabase client failed to initialize.</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-background">
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-sm space-y-6"
      >
        <div className="text-center space-y-1">
          <h1 className="text-xl font-semibold tracking-tight">Your profile</h1>
          <p className="text-sm text-muted-foreground">
            Sign in with email. We’ll send a 8-digit code — stay on this page and enter it here (works on your phone
            without localhost links).
          </p>
        </div>

        {step === 'email' && (
          <form onSubmit={sendCode} className="space-y-4">
            <Input
              type="email"
              required
              autoComplete="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="rounded-xl h-11 bg-secondary/50 border-0"
            />
            <Button type="submit" className="w-full h-11 rounded-xl" disabled={busy}>
              {busy ? 'Sending…' : 'Email me a code'}
            </Button>
          </form>
        )}

        {step === 'code' && (
          <form onSubmit={verifyCode} className="space-y-5">
            <p className="text-xs text-muted-foreground text-center">{email}</p>
            <div className="flex justify-center">
              <InputOTP maxLength={8} value={otp} onChange={setOtp} inputMode="numeric">
                <InputOTPGroup>
                  <InputOTPSlot index={0} />
                  <InputOTPSlot index={1} />
                  <InputOTPSlot index={2} />
                  <InputOTPSlot index={3} />
                  <InputOTPSlot index={4} />
                  <InputOTPSlot index={5} />
                  <InputOTPSlot index={6} />
                  <InputOTPSlot index={7} />
                </InputOTPGroup>
              </InputOTP>
            </div>
            <Button type="submit" className="w-full h-11 rounded-xl" disabled={busy || otp.length !== 8}>
              {busy ? 'Checking…' : 'Verify & continue'}
            </Button>
            <button
              type="button"
              className="w-full text-xs text-muted-foreground hover:text-foreground"
              onClick={() => {
                setStep('email');
                setOtp('');
                setStatus('');
              }}
            >
              Use a different email
            </button>
            <button type="button" className="w-full text-xs text-primary" onClick={sendCode} disabled={busy}>
              Resend code
            </button>
          </form>
        )}

        {status && <p className="text-xs text-center text-muted-foreground">{status}</p>}

        <p className="text-[10px] text-muted-foreground text-center leading-relaxed">
          In Supabase: Authentication → Emails → ensure the sign-in template includes the one-time code{' '}
          <code className="text-[10px]">{'{{ .Token }}'}</code> (OTP). If emails only contain a magic link, switch the
          template to OTP or add the code.
        </p>

        <Button variant="ghost" className="w-full rounded-xl" onClick={() => navigate('/')}>
          Back
        </Button>
      </motion.div>
    </div>
  );
}
