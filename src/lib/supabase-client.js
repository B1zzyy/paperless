import { createClient } from '@supabase/supabase-js';
import { getSupabaseCredentials, isSupabaseMode } from '@/lib/supabase-config';

let client = null;

export function getSupabase() {
  if (!isSupabaseMode()) return null;
  if (!client) {
    const { url, anonKey } = getSupabaseCredentials();
    client = createClient(url, anonKey, {
      auth: { persistSession: true, autoRefreshToken: true },
    });
  }
  return client;
}
