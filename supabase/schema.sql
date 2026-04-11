-- Run this in Supabase SQL Editor (or migrate) before using VITE_USE_SUPABASE=true
-- Receipts belong to the signed-in user (profile = auth.users + optional profiles table later).

create extension if not exists "pgcrypto";

create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  store_name text not null,
  store_address text,
  purchase_date timestamptz,
  items jsonb not null default '[]'::jsonb,
  subtotal numeric,
  tax numeric,
  total numeric not null,
  currency text default 'USD',
  payment_method text,
  receipt_id text,
  created_at timestamptz not null default now()
);

create index if not exists receipts_user_purchase_idx on public.receipts (user_id, purchase_date desc nulls last);

create table if not exists public.shared_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  receipt_id text not null,
  split_percent numeric not null,
  receipt_snapshot jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.receipts enable row level security;
alter table public.shared_receipts enable row level security;

drop policy if exists "receipts_select_own" on public.receipts;
drop policy if exists "receipts_insert_own" on public.receipts;
drop policy if exists "receipts_update_own" on public.receipts;
drop policy if exists "receipts_delete_own" on public.receipts;
drop policy if exists "shared_select_any" on public.shared_receipts;
drop policy if exists "shared_insert_auth" on public.shared_receipts;

-- Each customer only sees their own receipts
create policy "receipts_select_own" on public.receipts for select using (auth.uid() = user_id);
create policy "receipts_insert_own" on public.receipts for insert with check (auth.uid() = user_id);
create policy "receipts_update_own" on public.receipts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "receipts_delete_own" on public.receipts for delete using (auth.uid() = user_id);

-- Anyone with the link can open a shared split (read-only)
create policy "shared_select_any" on public.shared_receipts for select using (true);
create policy "shared_insert_auth" on public.shared_receipts for insert with check (auth.uid() is not null);

-- Auth: use Email magic link in the app (/login). Anonymous users are not used.
-- Optional later: create table public.profiles (id uuid primary key references auth.users, display_name text, ...);
