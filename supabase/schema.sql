-- Invoice GO cloud database (replaces Firestore).
-- Auth stays on Firebase. In Supabase: Authentication → Third-party auth → Firebase,
-- project ID aiinvoicemaker-3a0af. Then run this script in the SQL editor.
--
-- Row access uses the Firebase ID token `sub` claim (the Firebase uid).
-- No Firebase Cloud Function is required. Tokens without role=authenticated
-- are treated as anon, so policies allow anon only when sub matches the row.

create table if not exists public.users (
  id text primary key,
  email text,
  display_name text,
  google_photo_url text,
  photo_url text,
  auth_provider text,
  last_sign_in_at timestamptz,
  created_at timestamptz not null default now(),
  subscription_tier text not null default 'free',
  is_pro boolean not null default false,
  subscription_product_id text,
  subscription_platform text default 'google_play',
  subscription_purchase_id text,
  subscription_updated_at timestamptz,
  business_name text not null default '',
  business_email text not null default '',
  business_phone text not null default '',
  business_address text not null default '',
  business_tax_id text not null default '',
  business_logo_url text,
  business_updated_at timestamptz,
  language_code text,
  preferences_updated_at timestamptz,
  fcm_token text,
  fcm_updated_at timestamptz,
  invoice_day_key text,
  invoices_created_today integer not null default 0,
  daily_limit integer not null default 0,
  usage_updated_at timestamptz
);

create table if not exists public.subscription_events (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.users (id) on delete cascade,
  tier text not null,
  is_pro boolean not null default false,
  product_id text,
  platform text not null default 'google_play',
  purchase_id text,
  created_at timestamptz not null default now()
);

create index if not exists subscription_events_user_id_idx
  on public.subscription_events (user_id);

create table if not exists public.app_feedback (
  id uuid primary key default gen_random_uuid(),
  stars integer not null,
  comment text not null default '',
  uid text,
  platform text not null default 'android',
  package_id text,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;
alter table public.subscription_events enable row level security;
alter table public.app_feedback enable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.users to anon, authenticated;
grant select, insert, delete on public.subscription_events to anon, authenticated;
grant insert on public.app_feedback to anon, authenticated;

drop policy if exists users_select on public.users;
drop policy if exists users_insert on public.users;
drop policy if exists users_update on public.users;
drop policy if exists users_delete on public.users;
drop policy if exists subscription_events_select on public.subscription_events;
drop policy if exists subscription_events_insert on public.subscription_events;
drop policy if exists subscription_events_delete on public.subscription_events;
drop policy if exists app_feedback_insert on public.app_feedback;

create policy users_select on public.users
  for select to anon, authenticated
  using ((select auth.jwt() ->> 'sub') = id);

create policy users_insert on public.users
  for insert to anon, authenticated
  with check ((select auth.jwt() ->> 'sub') = id);

create policy users_update on public.users
  for update to anon, authenticated
  using ((select auth.jwt() ->> 'sub') = id)
  with check ((select auth.jwt() ->> 'sub') = id);

create policy users_delete on public.users
  for delete to anon, authenticated
  using ((select auth.jwt() ->> 'sub') = id);

create policy subscription_events_select on public.subscription_events
  for select to anon, authenticated
  using ((select auth.jwt() ->> 'sub') = user_id);

create policy subscription_events_insert on public.subscription_events
  for insert to anon, authenticated
  with check ((select auth.jwt() ->> 'sub') = user_id);

create policy subscription_events_delete on public.subscription_events
  for delete to anon, authenticated
  using ((select auth.jwt() ->> 'sub') = user_id);

create policy app_feedback_insert on public.app_feedback
  for insert to anon, authenticated
  with check (
    uid is null
    or uid = (select auth.jwt() ->> 'sub')
  );
