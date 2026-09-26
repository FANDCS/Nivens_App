-- Τρέξε αυτό στο Supabase SQL editor του project σου.

create table if not exists notes (
  id uuid primary key,
  user_id uuid references auth.users not null default auth.uid(),
  encrypted_content text not null,
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists daily_entries (
  id uuid primary key,
  user_id uuid references auth.users not null default auth.uid(),
  timestamp timestamptz not null default now(),
  encrypted_text text not null,
  tag text,
  weight int not null default 1
);

create table if not exists attachments (
  id uuid primary key,
  user_id uuid references auth.users not null default auth.uid(),
  note_id uuid references notes(id) on delete cascade,
  storage_path text not null,
  type text not null,
  created_at timestamptz not null default now()
);

alter table notes enable row level security;
alter table daily_entries enable row level security;
alter table attachments enable row level security;

create policy "Users manage their own notes"
  on notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage their own daily entries"
  on daily_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage their own attachments"
  on attachments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────
-- Γενικό sync system (copied/adapted από το Callen App): ΕΝΑΣ πίνακας για
-- όλα τα συγχρονιζόμενα δεδομένα (σημειώσεις + καθημερινά), όπου κάθε
-- γραμμή είναι ήδη κρυπτογραφημένη (AES-256-GCM) από την εφαρμογή πριν
-- φτάσει εδώ - ο τύπος περιεχομένου ('note' / 'daily_entry') κρύβεται ΜΕΣΑ
-- στο `payload`, όχι σε ξεχωριστή στήλη. Δες lib/core/sync/.
--
-- Χρησιμοποιεί το ίδιο μοντέλο ασφάλειας με τα παραπάνω: anon key + RLS,
-- ΧΩΡΙΣ Supabase Auth (δεν χρειάζεται sign-in σε άλλες συσκευές, αρκεί να
-- μοιραστείς το ίδιο project URL + anon key + κωδικό κρυπτογράφησης).
create table if not exists public.sync_entries (
  entry_id       text primary key,        -- σταθερό id της εγγραφής (uuid, ίδιο με το τοπικό)
  device_origin  text not null,           -- ποια συσκευή τη δημιούργησε (καθαρό κείμενο)
  payload        text not null,           -- ΚΡΥΠΤΟΓΡΑΦΗΜΕΝΟ blob (base64)
  updated_at     timestamptz not null default now()
);

create index if not exists idx_sync_entries_updated_at
  on public.sync_entries (updated_at);

alter table public.sync_entries enable row level security;

drop policy if exists "anon full access" on public.sync_entries;
create policy "anon full access"
  on public.sync_entries
  for all
  to anon
  using (true)
  with check (true);
