import { isSupabaseMode } from '@/lib/supabase-config';
import { getSupabase } from '@/lib/supabase-client';
import { createSupabaseDbAdapter } from '@/lib/supabase-db-adapter';

if (isSupabaseMode()) {
  const supabase = getSupabase();
  if (supabase) {
    globalThis.__B44_DB__ = createSupabaseDbAdapter(supabase);
  }
}
