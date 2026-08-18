-- =====================================================================
-- PharmaPath — B.Pharm Exam Companion
-- Database schema (PostgreSQL / Supabase compatible)
-- Use with FlutterFlow+Supabase path, or as the design reference
-- for Google Sheets tabs (Glide path: one tab per table, same columns).
-- 17 tables · v1.0 · 18 Aug 2026
-- =====================================================================

-- 1. USERS ------------------------------------------------------------
create table users (
  id            uuid primary key default gen_random_uuid(),
  phone         text unique not null,          -- +91 login identity
  email         text,
  name          text,
  language_pref text not null default 'hinglish' check (language_pref in ('en','hinglish','hi')),
  semester      int  check (semester between 1 and 8),
  college       text,
  university    text default 'RUHS',
  plan_tier     text not null default 'free' check (plan_tier in ('free','premium')),
  night_mode    boolean not null default false,
  font_size     int not null default 15,
  scanner_quota_left int not null default 3,   -- free tier: 3/month
  created_at    timestamptz not null default now(),
  last_active   timestamptz
);

-- 2. SEMESTERS --------------------------------------------------------
create table semesters (
  id          int primary key check (id between 1 and 8),
  sem_no      int unique not null,
  title       text not null,                   -- 'Semester 4 — Core Medical'
  category    text not null check (category in ('foundation','core_medical','advanced_clinical')),
  scheme      text not null default 'pci_2019' check (scheme in ('pci_2019','nep_2026')),
  description text,
  icon        text
);

-- 3. SUBJECTS ---------------------------------------------------------
create table subjects (
  id               uuid primary key default gen_random_uuid(),
  sem_id           int not null references semesters(id),
  name             text not null,
  code             text not null,              -- PCI code: BP502T, BP704T...
  category         text not null check (category in ('foundation','core_medical','advanced_clinical')),
  units_count      int not null default 5,
  syllabus_text    text,
  color            text,
  icon             text,
  is_premium_subject boolean not null default false
);

-- 4. UNITS ------------------------------------------------------------
create table units (
  id          uuid primary key default gen_random_uuid(),
  subject_id  uuid not null references subjects(id) on delete cascade,
  unit_no     int not null check (unit_no between 1 and 5),
  title       text not null,
  description text
);

-- 5. NOTES (THE CONTENT TABLE — point-wise, bilingual, flowcharted) ---
create table notes (
  id                uuid primary key default gen_random_uuid(),
  unit_id           uuid references units(id) on delete cascade,
  subject_id        uuid not null references subjects(id),
  title             text not null,
  note_type         text not null check (note_type in ('topic','drug','answer','definition','flowchart')),
  en_points         jsonb not null,            -- array of strings: bullets ONLY
  hinglish_points   jsonb not null,            -- parallel array, same length
  hindi_points      jsonb,                     -- optional Devanagari
  flowchart_json    jsonb,                     -- {"steps":[{"id":1,"text_en":"..","text_hinglish":".."}],"arrows":[[1,2]]}
  marks             int check (marks in (2,5,10)),  -- RUHS answer size
  tags              jsonb not null default '[]',
  is_premium        boolean not null default false,
  source_session_id uuid references scanner_sessions(id),  -- audit trail for AI notes
  views             int not null default 0,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 6. DRUGS (monograph index + scanner matching dictionary) ------------
create table drugs (
  id                uuid primary key default gen_random_uuid(),
  name              text unique not null,
  aliases           jsonb not null default '[]',   -- brands + common spellings
  class             text,
  moa_points        jsonb not null default '[]',   -- point-wise mechanism
  uses              jsonb not null default '[]',
  side_effects      jsonb not null default '[]',
  contraindications jsonb not null default '[]',
  related_note_id   uuid references notes(id),
  subject_tags      jsonb not null default '[]'
);

-- 7. QUESTION PAPERS (RUHS PYQs) --------------------------------------
create table question_papers (
  id          uuid primary key default gen_random_uuid(),
  subject_id  uuid not null references subjects(id),
  year        int not null,
  term        text,
  paper_url   text,
  solved_url  text,
  is_premium  boolean not null default true
);

-- 8. QUESTIONS --------------------------------------------------------
create table questions (
  id             uuid primary key default gen_random_uuid(),
  subject_id     uuid not null references subjects(id),
  unit_id        uuid references units(id),
  question_text  text not null,
  marks          int check (marks in (2,5,8,10)),
  year           int,
  is_important   boolean not null default false,
  answer_note_id uuid references notes(id)
);

-- 9. SCANNER SESSIONS (one per uploaded screenshot) -------------------
create table scanner_sessions (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references users(id),
  image_url            text not null,
  source_type          text not null check (source_type in ('syllabus','question_paper','drug_list')),
  status               text not null default 'processing'
                         check (status in ('processing','reviewed','completed','failed')),
  extracted_items_json jsonb,                    -- raw AI extraction (audit)
  validation_log       jsonb,                    -- {kept:[..], rejected:[..]} strict rule
  prompt_version       text,
  created_at           timestamptz not null default now()
);

-- 10. SCAN ITEMS (each extracted item + its generated note) -----------
create table scan_items (
  id                uuid primary key default gen_random_uuid(),
  session_id        uuid not null references scanner_sessions(id) on delete cascade,
  item_name         text not null,               -- EXACT text as in image
  item_type         text check (item_type in ('drug','topic','unit','question')),
  matched_drug_id   uuid references drugs(id),
  generated_note_id uuid references notes(id),
  status            text not null default 'pending'
                      check (status in ('pending','generated','library','rejected_by_validation'))
);

-- 11. BOOKMARKS -------------------------------------------------------
create table bookmarks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  item_type  text not null check (item_type in ('note','drug','question','paper')),
  item_id    uuid not null,
  created_at timestamptz not null default now()
);

-- 12. PROGRESS --------------------------------------------------------
create table progress (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users(id) on delete cascade,
  item_type      text not null check (item_type in ('note','unit','question')),
  item_id        uuid not null,
  status         text not null default 'started' check (status in ('started','done')),
  last_studied_at timestamptz not null default now(),
  study_seconds  int not null default 0,
  unique (user_id, item_type, item_id)
);

-- 13. FLASHCARDS ------------------------------------------------------
create table flashcards (
  id             uuid primary key default gen_random_uuid(),
  note_id        uuid references notes(id),
  unit_id        uuid references units(id),
  front_en       text not null,
  front_hinglish text not null,
  back_en        text not null,
  back_hinglish  text not null
);

-- 14. GLOSSARY (jargon -> simple words) -------------------------------
create table glossary (
  id           uuid primary key default gen_random_uuid(),
  term         text unique not null,
  simple_en    text not null,
  hinglish     text not null,
  subject_tags jsonb not null default '[]'
);

-- 15. PURCHASES -------------------------------------------------------
create table purchases (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id),
  plan_id    uuid not null references subscription_plans(id),
  amount     int not null,                       -- paise (₹499 -> 49900)
  currency   text not null default 'INR',
  gateway    text not null default 'razorpay',
  payment_id text,
  status     text not null default 'pending' check (status in ('pending','paid','failed','refunded')),
  valid_until timestamptz,
  created_at timestamptz not null default now()
);

-- 16. SUBSCRIPTION PLANS ----------------------------------------------
create table subscription_plans (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  price         int not null,
  duration_days int not null,
  features_json jsonb not null default '{}'
);

-- 17. APP META (content/prompt versioning, banners) -------------------
create table app_meta (
  key   text primary key,
  value jsonb
);

-- =====================================================================
-- INDEXES (search & speed)
-- =====================================================================
create index idx_subjects_sem      on subjects(sem_id);
create index idx_units_subject     on units(subject_id);
create index idx_notes_subject     on notes(subject_id);
create index idx_notes_unit        on notes(unit_id);
create index idx_questions_subject on questions(subject_id);
create index idx_scanitems_session on scan_items(session_id);
create index idx_purchases_user    on purchases(user_id);
create index idx_progress_user     on progress(user_id);
create index idx_bookmarks_user    on bookmarks(user_id);

-- =====================================================================
-- SEED — the 8 semesters
-- =====================================================================
insert into semesters (id, sem_no, title, category, scheme, icon) values
 (1,1,'Semester 1 — Foundation','foundation','pci_2019','🧪'),
 (2,2,'Semester 2 — Foundation','foundation','pci_2019','⚗️'),
 (3,3,'Semester 3 — Foundation','foundation','pci_2019','🔬'),
 (4,4,'Semester 4 — Core Medical','core_medical','pci_2019','💊'),
 (5,5,'Semester 5 — Core Medical','core_medical','pci_2019','🩺'),
 (6,6,'Semester 6 — Core Medical','core_medical','pci_2019','🧬'),
 (7,7,'Semester 7 — Advanced & Clinical','advanced_clinical','pci_2019','🏥'),
 (8,8,'Semester 8 — Advanced & Clinical','advanced_clinical','pci_2019','📊');

-- =====================================================================
-- SEED — sample drug (Tetracycline) + sample note (MOA flowchart)
-- =====================================================================
insert into drugs (name, aliases, class, moa_points, uses, side_effects) values
 ('Tetracycline','["Achromycin","tetrasaiklin","Tetracycline HCl"]','Tetracyclines',
  '["Penetrates bacterial cell wall via porin channels (passive diffusion)","Binds 30S ribosomal subunit (reversible)","Blocks binding of aminoacyl-tRNA to the A-site","Stops protein synthesis -> bacteriostatic action"]',
  '["Acne","Cholera","Plague","Brucellosis","Rickettsial infections"]',
  '["GI irritation","Photosensitivity","Tooth discoloration (children)","Hepatotoxicity (high dose)"]');

insert into notes (unit_id, subject_id, title, note_type, en_points, hinglish_points, flowchart_json, marks, tags, is_premium)
values (null, null, 'Tetracycline — Mechanism of Action', 'drug',
 '["Enters bacterial cell by passive diffusion through porin channels","Binds reversibly to the 30S ribosomal subunit","Blocks aminoacyl-tRNA binding at the A-site","Protein synthesis stops — bacteriostatic effect","Resistance: efflux pumps + ribosomal protection proteins"]',
 '["Porin channels se passive diffusion ke through bacteria ke andar jata hai","30S ribosomal subunit se reversibly bind karta hai","A-site par aminoacyl-tRNA ko bind hone se rokta hai","Protein synthesis ruk jati hai — isliye bacteriostatic hai","Resistance: efflux pumps aur ribosomal protection proteins se"]',
 '{"steps":[{"id":1,"text_en":"Diffusion via porins","text_hinglish":"Porins se andar ghusta hai"},{"id":2,"text_en":"Binds 30S subunit","text_hinglish":"30S subunit se judta hai"},{"id":3,"text_en":"Blocks tRNA at A-site","text_hinglish":"A-site par tRNA block"},{"id":4,"text_en":"Protein synthesis stops","text_hinglish":"Protein banana band"}],"arrows":[[1,2],[2,3],[3,4]]}',
 10, '["antibiotic","MOA","chemotherapy"]', false);

-- =====================================================================
-- SEED — sample RUHS question + scanner audit example
-- =====================================================================
insert into questions (subject_id, unit_id, question_text, marks, year, is_important, answer_note_id)
values (null, null, 'Explain the mechanism of action of tetracycline.', 10, 2023, true, (select id from notes where title='Tetracycline — Mechanism of Action'));

-- Scanner audit trail example (validation log = the strict rule proof)
insert into scanner_sessions (user_id, image_url, source_type, status,
  extracted_items_json, validation_log, prompt_version)
values (null, 'https://storage.example/syllabus_photo.jpg', 'drug_list', 'completed',
 '["Tetracycline","Sulfonamides","Chloramphenicol","Erythromycin","Griseofulvin"]',
 '{"kept":["Tetracycline","Sulfonamides","Chloramphenicol","Erythromycin","Griseofulvin"],"rejected":[]}',
 'promptA-v2/promptB-v2/promptC-v2');
