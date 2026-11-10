-- ZankoSwap Supabase setup: run once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  "displayName" text default '',
  email text default '',
  phone text default '',
  "photoUrl" text,
  "updatedAt" timestamptz default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles own select" on public.profiles;
create policy "profiles own select" on public.profiles for select to authenticated using (auth.uid()=id);
drop policy if exists "profiles own insert" on public.profiles;
create policy "profiles own insert" on public.profiles for insert to authenticated with check (auth.uid()=id);
drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);

create table if not exists public.listings (
 id uuid primary key default gen_random_uuid(),
 "sellerId" uuid not null references auth.users(id) on delete cascade,
 "sellerName" text default '',
 title text not null,
 description text default '',
 type text default 'book',
 "transactionType" text default 'free',
 "priceIQD" integer default 0,
 condition text default 'good',
 edition text, subject text, semester integer,
 images text[] default '{}', "pdfUrl" text,
 "cityId" text default '', "universityId" text default '', "universityName" text default '',
 "collegeId" text default '', "departmentId" text default '', stage integer default 1, "stageLabel" text default '',
 status text default 'active', "viewCount" integer default 0, "favoriteCount" integer default 0,
 "createdAt" timestamptz default now(), "updatedAt" timestamptz default now()
);
alter table public.listings enable row level security;
drop policy if exists "listings public read" on public.listings;
create policy "listings public read" on public.listings for select to authenticated using (true);
drop policy if exists "listings own insert" on public.listings;
create policy "listings own insert" on public.listings for insert to authenticated with check (auth.uid()="sellerId");
drop policy if exists "listings own update" on public.listings;
create policy "listings own update" on public.listings for update to authenticated using (auth.uid()="sellerId") with check (auth.uid()="sellerId");
drop policy if exists "listings own delete" on public.listings;
create policy "listings own delete" on public.listings for delete to authenticated using (auth.uid()="sellerId");

create table if not exists public.institutions (
 id uuid primary key default gen_random_uuid(), type text default 'college',
 "nameKu" text default '', "nameEn" text default '', city text default '',
 "descriptionKu" text default '', "descriptionEn" text default '', "websiteUrl" text default '',
 "instagramUrl" text default '', "facebookUrl" text default '', phone text default '', address text default '',
 "logoUrl" text default '', active boolean default true, "durationYears" integer default 0, "admissionAfterGrade9" boolean default false, "studyLanguage" text default '', "specialties" text default '', "updatedAt" timestamptz default now()
);
alter table public.institutions add column if not exists "durationYears" integer default 0;
alter table public.institutions add column if not exists "admissionAfterGrade9" boolean default false;
alter table public.institutions add column if not exists "studyLanguage" text default '';
alter table public.institutions add column if not exists "specialties" text default '';
alter table public.institutions enable row level security;
drop policy if exists "institutions authenticated read" on public.institutions;
create policy "institutions authenticated read" on public.institutions for select to authenticated using (true);

create table if not exists public.research (
 id uuid primary key default gen_random_uuid(), "authorId" uuid references auth.users(id) on delete set null,
 "authorName" text default '', title text default '', description text default '', "linkOrContent" text default '',
 "departmentId" text default '', "universityId" text default '', "collegeId" text default '', stage integer default 1,
 "createdAt" timestamptz default now()
);
alter table public.research enable row level security;
drop policy if exists "research authenticated read" on public.research;
create policy "research authenticated read" on public.research for select to authenticated using (true);
drop policy if exists "research own insert" on public.research;
create policy "research own insert" on public.research for insert to authenticated with check (auth.uid()="authorId");

do $$ begin
 if to_regclass('public."examPapers"') is not null and to_regclass('public.exam_papers') is null then
   alter table public."examPapers" rename to exam_papers;
 end if;
end $$;

create table if not exists public.exam_papers (
 id uuid primary key default gen_random_uuid(), "authorId" uuid references auth.users(id) on delete set null,
 "authorName" text default '', subject text default '', track text default 'scientific', year text default '', content text default '', images text[] not null default '{}',
 "createdAt" timestamptz default now()
);
alter table public.exam_papers enable row level security;
drop policy if exists "exam papers authenticated read" on public.exam_papers;
create policy "exam papers authenticated read" on public.exam_papers for select to authenticated using (true);
drop policy if exists "exam papers own insert" on public.exam_papers;
create policy "exam papers own insert" on public.exam_papers for insert to authenticated with check (auth.uid()="authorId");

create table if not exists public.ad_campaigns (
 id uuid primary key default gen_random_uuid(), title text default '', subtitle text default '', advertiser text default '',
 "imageUrl" text default '', placement text default 'home', status text default 'pending', "budgetIQD" integer default 0,
 days integer default 7, "createdAt" timestamptz default now(), "targetRoute" text
);
alter table public.ad_campaigns enable row level security;
drop policy if exists "ads approved read" on public.ad_campaigns;
create policy "ads approved read" on public.ad_campaigns for select to authenticated using (status='approved');
drop policy if exists "ads auth insert" on public.ad_campaigns;
create policy "ads auth insert" on public.ad_campaigns for insert to authenticated with check (true);

create table if not exists public.chats (
 id text primary key, "buyerId" uuid references auth.users(id), "sellerId" uuid references auth.users(id), "listingId" uuid references public.listings(id),
 "lastMessage" text default '', "lastMessageAt" timestamptz, "updatedAt" timestamptz default now()
);
alter table public.chats enable row level security;
drop policy if exists "chat participants read" on public.chats;
create policy "chat participants read" on public.chats for select to authenticated using (auth.uid()="buyerId" or auth.uid()="sellerId");
drop policy if exists "chat participants insert" on public.chats;
create policy "chat participants insert" on public.chats for insert to authenticated with check (auth.uid()="buyerId" or auth.uid()="sellerId");
drop policy if exists "chat participants update" on public.chats;
create policy "chat participants update" on public.chats for update to authenticated using (auth.uid()="buyerId" or auth.uid()="sellerId");

create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(), "chatId" text references public.chats(id) on delete cascade, "senderId" uuid references auth.users(id),
 text text default '', type text default 'text', "isRead" boolean default false, "createdAt" timestamptz default now()
);
alter table public.messages enable row level security;
drop policy if exists "messages participants read" on public.messages;
create policy "messages participants read" on public.messages for select to authenticated using (exists(select 1 from public.chats c where c.id="chatId" and (c."buyerId"=auth.uid() or c."sellerId"=auth.uid())));
drop policy if exists "messages own insert" on public.messages;
create policy "messages own insert" on public.messages for insert to authenticated with check (auth.uid()="senderId");

create table if not exists public.services (
 id uuid primary key default gen_random_uuid(), "ownerId" uuid references auth.users(id) on delete cascade,
 name text not null, type text default '', address text default '', offer text default '',
 active boolean default true, "createdAt" timestamptz default now()
);
alter table public.services enable row level security;
drop policy if exists "services public read" on public.services;
create policy "services public read" on public.services for select to authenticated using (active=true);
drop policy if exists "services own insert" on public.services;
create policy "services own insert" on public.services for insert to authenticated with check (auth.uid()="ownerId");
drop policy if exists "services own update" on public.services;
create policy "services own update" on public.services for update to authenticated using (auth.uid()="ownerId") with check (auth.uid()="ownerId");

create table if not exists public.favorites (
 id uuid primary key default gen_random_uuid(), "userId" uuid references auth.users(id) on delete cascade, "listingId" uuid references public.listings(id) on delete cascade,
 unique("userId","listingId")
);
alter table public.favorites enable row level security;
drop policy if exists "favorites own all" on public.favorites;
create policy "favorites own all" on public.favorites for all to authenticated using (auth.uid()="userId") with check (auth.uid()="userId");

insert into storage.buckets (id,name,public) values ('profile-images','profile-images',true) on conflict (id) do update set public=true;
insert into storage.buckets (id,name,public) values ('listing-images','listing-images',true) on conflict (id) do update set public=true;
insert into storage.buckets (id,name,public) values ('services','services',true) on conflict (id) do update set public=true;

alter table storage.objects enable row level security;
drop policy if exists "profile images upload" on storage.objects;
create policy "profile images upload" on storage.objects for insert to authenticated with check (bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "profile images update" on storage.objects;
create policy "profile images update" on storage.objects for update to authenticated using (bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "profile images delete" on storage.objects;
create policy "profile images delete" on storage.objects for delete to authenticated using (bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "listing images upload" on storage.objects;
create policy "listing images upload" on storage.objects for insert to authenticated with check (bucket_id='listing-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "listing images update" on storage.objects;
create policy "listing images update" on storage.objects for update to authenticated using (bucket_id='listing-images' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='listing-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "listing images delete" on storage.objects;
create policy "listing images delete" on storage.objects for delete to authenticated using (bucket_id='listing-images' and (storage.foldername(name))[1]=auth.uid()::text);


-- Verified 5-year vocational route after grade 9 for 2026-2027.
-- The Ministry announcement covers Erbil, Sulaymaniyah and Garmian.
insert into public.institutions (type, "nameKu", "nameEn", city, "descriptionKu", "descriptionEn", active, "durationYears", "admissionAfterGrade9", "studyLanguage", specialties)
select 'vocationalFiveYear', 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - هەولێر', 'English Vocational Institute - Erbil', 'هەولێر', 'خوێندنی ٥ ساڵە دوای پۆلی ٩. ساڵی یەکەم بۆ ئینگلیزییە و لە ساڵی دووەمەوە پسپۆڕی دەست پێدەکات.', 'Five-year study after grade 9. Year 1 focuses on English; specializations start from year 2.', true, 5, true, 'English', 'IT, Graphic Design, Interior Design, Accounting, Hotel & Hospitality')
where not exists (select 1 from public.institutions where type='vocationalFiveYear' and city='هەولێر' and "nameEn"='English Vocational Institute - Erbil');
insert into public.institutions (type, "nameKu", "nameEn", city, "descriptionKu", "descriptionEn", active, "durationYears", "admissionAfterGrade9", "studyLanguage", specialties)
select 'vocationalFiveYear', 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - سلێمانی', 'English Vocational Institute - Sulaymaniyah', 'سلێمانی', 'خوێندنی ٥ ساڵە دوای پۆلی ٩ بەپێی ئاگاداریی وەرگرتنی ٢٠٢٦-٢٠٢٧.', 'Five-year study after grade 9 according to the 2026-2027 admission announcement.', true, 5, true, 'English', 'IT, Graphic Design, Interior Design, Accounting, Hotel & Hospitality')
where not exists (select 1 from public.institutions where type='vocationalFiveYear' and city='سلێمانی' and "nameEn"='English Vocational Institute - Sulaymaniyah');
insert into public.institutions (type, "nameKu", "nameEn", city, "descriptionKu", "descriptionEn", active, "durationYears", "admissionAfterGrade9", "studyLanguage", specialties)
select 'vocationalFiveYear', 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - گەرمیان', 'English Vocational Institute - Garmian', 'گەرمیان', 'خوێندنی ٥ ساڵە دوای پۆلی ٩ بەپێی ئاگاداریی وەرگرتنی ٢٠٢٦-٢٠٢٧.', 'Five-year study after grade 9 according to the 2026-2027 admission announcement.', true, 5, true, 'English', 'IT, Graphic Design, Interior Design, Accounting, Hotel & Hospitality')
where not exists (select 1 from public.institutions where type='vocationalFiveYear' and city='گەرمیان' and "nameEn"='English Vocational Institute - Garmian');
