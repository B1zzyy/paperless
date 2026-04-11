/**
 * Mimics Base44's `globalThis.__B44_DB__` shape so existing pages keep working.
 * Receipts are scoped to `auth.uid()` via RLS + `user_id` on insert.
 */
export function createSupabaseDbAdapter(supabase) {
  const uploadStub = async () => ({ file_url: '' });

  async function currentUserId() {
    const { data: { user } } = await supabase.auth.getUser();
    return user?.id ?? null;
  }

  const Receipt = {
    async list(sort) {
      const uid = await currentUserId();
      if (!uid) return [];
      const field =
        typeof sort === 'string' && sort.length > 0
          ? sort.replace(/^[+-]/, '')
          : 'purchase_date';
      const descending = typeof sort === 'string' && sort.startsWith('-');
      const { data, error } = await supabase
        .from('receipts')
        .select('*')
        .eq('user_id', uid)
        .order(field, { ascending: !descending, nullsFirst: false });
      if (error) throw error;
      return data ?? [];
    },

    async filter(query) {
      const uid = await currentUserId();
      let q = supabase.from('receipts').select('*');
      if (query?.id != null) q = q.eq('id', String(query.id));
      if (uid) q = q.eq('user_id', uid);
      const { data, error } = await q;
      if (error) throw error;
      return data ?? [];
    },

    async create(payload) {
      const uid = await currentUserId();
      if (!uid) throw new Error('Sign in required to save receipts.');
      const row = {
        user_id: uid,
        store_name: payload.store_name,
        store_address: payload.store_address ?? null,
        purchase_date: payload.purchase_date ?? new Date().toISOString(),
        items: payload.items ?? [],
        subtotal: payload.subtotal ?? null,
        tax: payload.tax ?? null,
        total: payload.total,
        currency: payload.currency ?? 'USD',
        payment_method: payload.payment_method ?? null,
        receipt_id: payload.receipt_id ?? null,
      };
      const { data, error } = await supabase.from('receipts').insert(row).select('*').single();
      if (error) throw error;
      return data;
    },
  };

  const SharedReceipt = {
    async filter(query) {
      let q = supabase.from('shared_receipts').select('*');
      if (query?.id != null) q = q.eq('id', String(query.id));
      const { data, error } = await q;
      if (error) throw error;
      return data ?? [];
    },

    async create(payload) {
      const uid = await currentUserId();
      if (!uid) throw new Error('Sign in required to share receipts.');
      const row = {
        user_id: uid,
        receipt_id: String(payload.receipt_id),
        split_percent: payload.split_percent,
        receipt_snapshot: payload.receipt_snapshot,
      };
      const { data, error } = await supabase
        .from('shared_receipts')
        .insert(row)
        .select('*')
        .single();
      if (error) throw error;
      return data;
    },
  };

  return {
    auth: {
      async isAuthenticated() {
        const { data: { session } } = await supabase.auth.getSession();
        return Boolean(session);
      },
      async me() {
        const { data: { user }, error } = await supabase.auth.getUser();
        if (error || !user) return null;
        return {
          id: user.id,
          email: user.email,
          role: user.role ?? 'user',
        };
      },
      logout(redirectHref) {
        supabase.auth.signOut().then(() => {
          if (redirectHref) window.location.assign(redirectHref);
        });
      },
      redirectToLogin(returnUrl) {
        const next = encodeURIComponent(returnUrl || window.location.href);
        window.location.assign(`/login?next=${next}`);
      },
    },
    entities: { Receipt, SharedReceipt },
    integrations: { Core: { UploadFile: uploadStub } },
  };
}
