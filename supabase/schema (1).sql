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

-- Attachments metadata (τα ίδια τα κρυπτογραφημένα bytes πάνε σε Storage bucket)
create table if not exists attachments (
  id uuid primary key,
  user_id uuid references auth.users not null default auth.uid(),
  note_id uuid references notes(id) on delete cascade,
  storage_path text not null,
  type text not null, -- image | audio | video | drawing
  created_at timestamptz not null default now()
);

-- Row Level Security: ο καθένας βλέπει/γράφει ΜΟΝΟ τα δικά του δεδομένα.
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

-- Δημιούργησε επίσης ένα private Storage bucket "attachments" από το
-- Supabase dashboard (Storage -> New bucket -> Public: OFF) για τα
-- κρυπτογραφημένα αρχεία πολυμέσων.
