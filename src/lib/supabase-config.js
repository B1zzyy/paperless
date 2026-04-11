/** Trim env values — spaces after `=` in .env break the anon key. */
export function getSupabaseCredentials() {
  const url = String(import.meta.env.VITE_SUPABASE_URL ?? '')
    .trim()
    .replace(/\/$/, '');
  const anonKey = String(import.meta.env.VITE_SUPABASE_ANON_KEY ?? '').trim();
  return { url, anonKey };
}

/** When true, the app uses your Supabase project instead of Base44 for data + auth. */
export function isSupabaseMode() {
  const { url, anonKey } = getSupabaseCredentials();
  return import.meta.env.VITE_USE_SUPABASE === 'true' && Boolean(url) && Boolean(anonKey);
}
