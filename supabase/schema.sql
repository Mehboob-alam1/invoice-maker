-- Invoice GO cloud database. Supabase is the only database.
-- Firebase is limited to Auth, Cloud Messaging, Remote Config, and Analytics.
-- In Supabase: Authentication → Third-party auth → Firebase,
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
grant insert, delete on public.app_feedback to anon, authenticated;

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
  for select to authenticated
  using ((select auth.jwt() ->> 'sub') = user_id);

create policy subscription_events_insert on public.subscription_events
  for insert to authenticated
  with check ((select auth.jwt() ->> 'sub') = user_id);

create policy subscription_events_delete on public.subscription_events
  for delete to authenticated
  using ((select auth.jwt() ->> 'sub') = user_id);

create policy app_feedback_insert on public.app_feedback
  for insert to anon, authenticated
  with check (
    uid is null
    or uid = (select auth.jwt() ->> 'sub')
  );

drop policy if exists app_feedback_delete on public.app_feedback;
create policy app_feedback_delete on public.app_feedback
  for delete to anon, authenticated
  using (uid = (select auth.jwt() ->> 'sub'));

-- Referral balances live here. The app reads them. Only the functions below
-- may change a code, a reward, or who referred whom.
alter table public.users
  add column if not exists referral_code text,
  add column if not exists referred_by text,
  add column if not exists referral_qualified boolean not null default false,
  add column if not exists referral_count integer not null default 0,
  add column if not exists bonus_ai_credits integer not null default 0,
  add column if not exists template_tokens integer not null default 0,
  add column if not exists referral_pro_until timestamptz,
  add column if not exists installation_id text,
  add column if not exists referral_month_key text,
  add column if not exists referral_month_count integer not null default 0,
  add column if not exists qualify_times timestamptz[] not null default '{}',
  add column if not exists granted_milestones integer[] not null default '{}',
  add column if not exists token_unlocked_templates text[] not null default '{}';

create unique index if not exists users_referral_code_idx
  on public.users (referral_code)
  where referral_code is not null;

create table if not exists public.referral_codes (
  code text primary key,
  uid text not null references public.users (id) on delete cascade
);

create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_uid text not null references public.users (id) on delete cascade,
  referee_uid text not null references public.users (id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  qualified_at timestamptz,
  reject_reason text
);

create index if not exists referrals_referee_status_idx
  on public.referrals (referee_uid, status);

create table if not exists public.reward_ledger (
  id uuid primary key default gen_random_uuid(),
  uid text not null references public.users (id) on delete cascade,
  type text not null,
  amount integer not null,
  source text not null,
  referral_id uuid,
  template_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.installations (
  id text primary key,
  uid text not null references public.users (id) on delete cascade,
  referrer_uid text,
  created_at timestamptz not null default now()
);

create table if not exists public.referral_config (
  id integer primary key default 1 check (id = 1),
  referrer_ai_credits integer not null default 5,
  referee_ai_credits integer not null default 3,
  referrer_template_tokens integer not null default 1,
  referee_template_tokens integer not null default 1,
  monthly_cap integer not null default 20,
  milestones jsonb not null default '[
    {"count":1,"type":"template_token","amount":1},
    {"count":3,"type":"pro_days","amount":3},
    {"count":5,"type":"ai_credits","amount":10},
    {"count":10,"type":"pro_days","amount":30}
  ]'::jsonb
);

insert into public.referral_config (id) values (1) on conflict (id) do nothing;

alter table public.referral_codes enable row level security;
alter table public.referrals enable row level security;
alter table public.reward_ledger enable row level security;
alter table public.installations enable row level security;
alter table public.referral_config enable row level security;

grant select on public.referral_codes to anon, authenticated;
grant select on public.referrals to anon, authenticated;
grant select on public.reward_ledger to anon, authenticated;
grant select on public.referral_config to anon, authenticated;

drop policy if exists referral_codes_select on public.referral_codes;
drop policy if exists referrals_select on public.referrals;
drop policy if exists reward_ledger_select on public.reward_ledger;
drop policy if exists referral_config_select on public.referral_config;

create policy referral_codes_select on public.referral_codes
  for select to anon, authenticated
  using (uid = (select auth.jwt() ->> 'sub'));

create policy referrals_select on public.referrals
  for select to anon, authenticated
  using (
    referrer_uid = (select auth.jwt() ->> 'sub')
    or referee_uid = (select auth.jwt() ->> 'sub')
  );

create policy reward_ledger_select on public.reward_ledger
  for select to anon, authenticated
  using (uid = (select auth.jwt() ->> 'sub'));

create policy referral_config_select on public.referral_config
  for select to anon, authenticated
  using (true);

-- Client upserts keep working, but they cannot change reward columns.
create or replace function public.protect_referral_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_setting('app.referral_write', true) = 'on' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.referral_code := null;
    new.referred_by := null;
    new.referral_qualified := false;
    new.referral_count := 0;
    new.bonus_ai_credits := 0;
    new.template_tokens := 0;
    new.referral_pro_until := null;
    new.installation_id := null;
    new.referral_month_key := null;
    new.referral_month_count := 0;
    new.qualify_times := '{}';
    new.granted_milestones := '{}';
    new.token_unlocked_templates := '{}';
    return new;
  end if;
  new.referral_code := old.referral_code;
  new.referred_by := old.referred_by;
  new.referral_qualified := old.referral_qualified;
  new.referral_count := old.referral_count;
  new.bonus_ai_credits := old.bonus_ai_credits;
  new.template_tokens := old.template_tokens;
  new.referral_pro_until := old.referral_pro_until;
  new.installation_id := old.installation_id;
  new.referral_month_key := old.referral_month_key;
  new.referral_month_count := old.referral_month_count;
  new.qualify_times := old.qualify_times;
  new.granted_milestones := old.granted_milestones;
  new.token_unlocked_templates := old.token_unlocked_templates;
  return new;
end;
$$;

drop trigger if exists users_protect_referral_columns on public.users;
create trigger users_protect_referral_columns
  before insert or update on public.users
  for each row execute function public.protect_referral_columns();

create or replace function public.normalize_referral_code(raw text)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  code text := upper(regexp_replace(coalesce(raw, ''), '[^A-Za-z0-9]', '', 'g'));
begin
  if code !~ '^[A-Z2-9]{6,8}$' or code ~ '[OI]' then
    return null;
  end if;
  return code;
end;
$$;

create or replace function public.referral_random_code()
returns text
language plpgsql
set search_path = public
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i integer;
begin
  for i in 1..7 loop
    result := result || substr(alphabet, 1 + floor(random() * length(alphabet))::integer, 1);
  end loop;
  return result;
end;
$$;

create or replace function public.ensure_referral_profile(
  p_installation_id text default null,
  p_fcm_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := nullif(auth.jwt() ->> 'sub', '');
  code text;
  attempt integer;
  pending_count integer;
  user_row public.users%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required.';
  end if;
  perform set_config('app.referral_write', 'on', true);
  insert into public.users (id) values (uid) on conflict (id) do nothing;
  select * into user_row from public.users where id = uid for update;
  if user_row.referral_code is null then
    for attempt in 1..8 loop
      code := public.referral_random_code();
      begin
        insert into public.referral_codes (code, uid) values (code, uid);
        update public.users set referral_code = code where id = uid;
        exit;
      exception when unique_violation then
        code := null;
      end;
    end loop;
    if code is null then
      raise exception 'Could not create a referral code.';
    end if;
  else
    code := user_row.referral_code;
  end if;
  if p_installation_id is not null and length(trim(p_installation_id)) >= 8 then
    update public.users set installation_id = trim(p_installation_id) where id = uid;
  end if;
  if p_fcm_token is not null and length(trim(p_fcm_token)) > 0 then
    update public.users
      set fcm_token = trim(p_fcm_token), fcm_updated_at = now()
      where id = uid;
  end if;
  select count(*) into pending_count
    from public.referrals
    where referrer_uid = uid and status = 'pending';
  select * into user_row from public.users where id = uid;
  return jsonb_build_object(
    'referralCode', user_row.referral_code,
    'bonusAiCredits', user_row.bonus_ai_credits,
    'templateTokens', user_row.template_tokens,
    'referralCount', user_row.referral_count,
    'pending', pending_count,
    'referredBy', user_row.referred_by,
    'referralProUntil', user_row.referral_pro_until,
    'serverNow', now(),
    'tokenUnlockedTemplates', to_jsonb(user_row.token_unlocked_templates)
  );
end;
$$;

create or replace function public.apply_referral_code(
  p_code text,
  p_installation_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := nullif(auth.jwt() ->> 'sub', '');
  code text := public.normalize_referral_code(p_code);
  referrer text;
  user_row public.users%rowtype;
  referrer_row public.users%rowtype;
  install_row public.installations%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required.';
  end if;
  if code is null then
    raise exception 'Enter a valid code.';
  end if;
  if p_installation_id is null or length(trim(p_installation_id)) < 8 then
    raise exception 'Missing installation id.';
  end if;
  perform set_config('app.referral_write', 'on', true);
  perform public.ensure_referral_profile(p_installation_id, null);
  select referral_codes.uid into referrer
    from public.referral_codes
    where referral_codes.code = code;
  if referrer is null then
    raise exception 'That code was not found.';
  end if;
  if referrer = uid then
    raise exception 'You cannot use your own code.';
  end if;
  select * into user_row from public.users where id = uid for update;
  if user_row.referred_by is not null then
    raise exception 'A code is already applied.';
  end if;
  if user_row.created_at < now() - interval '7 days' then
    raise exception 'Referral codes can only be added in the first 7 days.';
  end if;
  select * into install_row from public.installations where id = trim(p_installation_id);
  if install_row.id is not null and install_row.uid is distinct from uid then
    raise exception 'This device was already referred.';
  end if;
  select * into referrer_row from public.users where id = referrer;
  if referrer_row.installation_id is not null
     and referrer_row.installation_id = trim(p_installation_id) then
    raise exception 'You cannot refer this device.';
  end if;
  update public.users
    set referred_by = referrer, installation_id = trim(p_installation_id)
    where id = uid;
  insert into public.installations (id, uid, referrer_uid)
    values (trim(p_installation_id), uid, referrer)
    on conflict (id) do update
      set uid = excluded.uid, referrer_uid = excluded.referrer_uid;
  insert into public.referrals (referrer_uid, referee_uid, status)
    values (referrer, uid, 'pending');
  return jsonb_build_object(
    'ok', true,
    'message', 'You and your friend will both get rewards after your first invoice.'
  );
end;
$$;

create or replace function public.qualify_referral()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := nullif(auth.jwt() ->> 'sub', '');
  referral public.referrals%rowtype;
  referrer public.users%rowtype;
  referee public.users%rowtype;
  cfg public.referral_config%rowtype;
  month_count integer;
  hour_count integer;
  next_count integer;
  granted integer[];
  milestone jsonb;
  milestone_index integer := 0;
  milestone_count integer;
  milestone_type text;
  milestone_amount integer;
  referrer_credits integer := 0;
  referrer_tokens integer := 0;
  pro_days integer := 0;
  pro_base timestamptz;
begin
  if uid is null then
    raise exception 'Sign in required.';
  end if;
  perform set_config('app.referral_write', 'on', true);
  update public.referrals
    set status = 'rejected', reject_reason = 'expired', qualified_at = now()
    where status = 'pending' and created_at < now() - interval '30 days';
  select * into referral
    from public.referrals
    where referee_uid = uid and status = 'pending'
    order by created_at
    limit 1
    for update;
  if referral.id is null then
    return jsonb_build_object('qualified', false);
  end if;
  select * into cfg from public.referral_config where id = 1;
  select * into referrer from public.users where id = referral.referrer_uid for update;
  select * into referee from public.users where id = uid for update;
  month_count := case
    when referrer.referral_month_key = to_char(now() at time zone 'utc', 'YYYY-MM')
      then referrer.referral_month_count
    else 0
  end;
  if month_count >= cfg.monthly_cap then
    update public.referrals
      set status = 'rejected', reject_reason = 'monthly_cap', qualified_at = now()
      where id = referral.id;
    return jsonb_build_object('qualified', false, 'reason', 'monthly_cap');
  end if;
  select count(*) into hour_count
    from unnest(referrer.qualify_times) as ts
    where ts >= now() - interval '1 hour';
  if hour_count >= 8 then
    update public.referrals
      set status = 'rejected', reject_reason = 'velocity', qualified_at = now()
      where id = referral.id;
    return jsonb_build_object('qualified', false, 'reason', 'velocity');
  end if;
  if referee.installation_id is not null
     and referee.installation_id = referrer.installation_id then
    update public.referrals
      set status = 'rejected', reject_reason = 'same_device', qualified_at = now()
      where id = referral.id;
    return jsonb_build_object('qualified', false, 'reason', 'same_device');
  end if;

  next_count := referrer.referral_count + 1;
  granted := referrer.granted_milestones;
  referrer_credits := cfg.referrer_ai_credits;
  referrer_tokens := cfg.referrer_template_tokens;
  while milestone_index < jsonb_array_length(cfg.milestones) loop
    milestone := cfg.milestones -> milestone_index;
    milestone_index := milestone_index + 1;
    milestone_count := (milestone ->> 'count')::integer;
    milestone_type := milestone ->> 'type';
    milestone_amount := (milestone ->> 'amount')::integer;
    if next_count >= milestone_count and not (milestone_count = any(granted)) then
      granted := granted || milestone_count;
      if milestone_type = 'ai_credits' then
        referrer_credits := referrer_credits + milestone_amount;
      elsif milestone_type = 'template_token' then
        referrer_tokens := referrer_tokens + milestone_amount;
      elsif milestone_type = 'pro_days' then
        pro_days := pro_days + milestone_amount;
      else
        continue;
      end if;
      insert into public.reward_ledger (uid, type, amount, source, referral_id)
        values (referrer.id, milestone_type, milestone_amount, 'milestone', referral.id);
    end if;
  end loop;

  pro_base := case
    when referrer.referral_pro_until is not null and referrer.referral_pro_until > now()
      then referrer.referral_pro_until
    else now()
  end;
  update public.referrals
    set status = 'qualified', qualified_at = now()
    where id = referral.id;
  update public.users
    set referral_count = next_count,
        referral_month_key = to_char(now() at time zone 'utc', 'YYYY-MM'),
        referral_month_count = month_count + 1,
        qualify_times = (
          select coalesce(array_agg(ts), '{}')
          from unnest(referrer.qualify_times || now()) as ts
          where ts >= now() - interval '1 hour'
        ),
        granted_milestones = granted,
        bonus_ai_credits = bonus_ai_credits + referrer_credits,
        template_tokens = template_tokens + referrer_tokens,
        referral_pro_until = case
          when pro_days > 0 then pro_base + make_interval(days => pro_days)
          else referral_pro_until
        end
    where id = referrer.id;
  update public.users
    set referral_qualified = true,
        bonus_ai_credits = bonus_ai_credits + cfg.referee_ai_credits,
        template_tokens = template_tokens + cfg.referee_template_tokens
    where id = uid;

  insert into public.reward_ledger (uid, type, amount, source, referral_id)
    values
      (referrer.id, 'ai_credits', cfg.referrer_ai_credits, 'referral_referrer', referral.id),
      (referrer.id, 'template_token', cfg.referrer_template_tokens, 'referral_referrer', referral.id),
      (uid, 'ai_credits', cfg.referee_ai_credits, 'referral_referee', referral.id),
      (uid, 'template_token', cfg.referee_template_tokens, 'referral_referee', referral.id);
  return jsonb_build_object('qualified', true);
end;
$$;

create or replace function public.spend_ai_credits(p_amount integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := nullif(auth.jwt() ->> 'sub', '');
  current_credits integer;
begin
  if uid is null then
    raise exception 'Sign in required.';
  end if;
  if p_amount is null or p_amount < 1 or p_amount > 20 then
    raise exception 'Invalid credit amount.';
  end if;
  perform set_config('app.referral_write', 'on', true);
  select bonus_ai_credits into current_credits
    from public.users where id = uid for update;
  if current_credits is null or current_credits < p_amount then
    raise exception 'Not enough bonus credits.';
  end if;
  update public.users
    set bonus_ai_credits = current_credits - p_amount
    where id = uid;
  return jsonb_build_object('bonusAiCredits', current_credits - p_amount);
end;
$$;

create or replace function public.spend_template_token(p_template_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := nullif(auth.jwt() ->> 'sub', '');
  current_tokens integer;
  unlocked text[];
begin
  if uid is null then
    raise exception 'Sign in required.';
  end if;
  if p_template_id is null or length(trim(p_template_id)) = 0 then
    raise exception 'Missing template.';
  end if;
  perform set_config('app.referral_write', 'on', true);
  select template_tokens, token_unlocked_templates
    into current_tokens, unlocked
    from public.users where id = uid for update;
  if current_tokens is null or current_tokens < 1 then
    raise exception 'No template tokens left.';
  end if;
  update public.users
    set template_tokens = current_tokens - 1,
        token_unlocked_templates = (
          select array_agg(distinct item)
          from unnest(unlocked || trim(p_template_id)) as item
        )
    where id = uid;
  insert into public.reward_ledger (uid, type, amount, source, template_id)
    values (uid, 'template_token', -1, 'template_spend', trim(p_template_id));
  return jsonb_build_object('templateTokens', current_tokens - 1);
end;
$$;

revoke all on function public.ensure_referral_profile(text, text) from public;
revoke all on function public.apply_referral_code(text, text) from public;
revoke all on function public.qualify_referral() from public;
revoke all on function public.spend_ai_credits(integer) from public;
revoke all on function public.spend_template_token(text) from public;
grant execute on function public.ensure_referral_profile(text, text) to anon, authenticated;
grant execute on function public.apply_referral_code(text, text) to anon, authenticated;
grant execute on function public.qualify_referral() to anon, authenticated;
grant execute on function public.spend_ai_credits(integer) to anon, authenticated;
grant execute on function public.spend_template_token(text) to anon, authenticated;

-- Device backup. The signed-in user can read and replace only their own snapshot.
create table if not exists public.user_backups (
  user_id text primary key references public.users (id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.user_backups enable row level security;
grant select, insert, update, delete on public.user_backups to anon, authenticated;

drop policy if exists user_backups_all on public.user_backups;
create policy user_backups_all on public.user_backups
  for all to anon, authenticated
  using ((select auth.jwt() ->> 'sub') = user_id)
  with check ((select auth.jwt() ->> 'sub') = user_id);
