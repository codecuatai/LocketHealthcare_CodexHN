-- VitaSnap: Hồ sơ (profiles) và kho ảnh (avatars, moment-photos).
-- Tài khoản do Firebase Auth quản lý; Supabase chỉ lưu dữ liệu (docs/adr/0001).
-- Request từ app mang Firebase ID token và chạy dưới role `anon`; mọi policy
-- dựa vào `sub` của token Firebase (docs/adr/0002).

-- UID Firebase của người gọi, hoặc null nếu request không mang token Firebase.
create or replace function public.firebase_uid()
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when coalesce(auth.jwt() ->> 'iss', '') like 'https://securetoken.google.com/%'
      then auth.jwt() ->> 'sub'
  end
$$;

-- ---------------------------------------------------------------------------
-- Hồ sơ
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id            text primary key check (char_length(id) between 1 and 128),
  email         text not null,
  display_name  text not null check (char_length(btrim(display_name)) between 1 and 60),
  avatar_url    text,
  -- Chỉ số sức khỏe: để trống cho tới khi có màn Onboarding.
  gender        text check (gender in ('male', 'female', 'other')),
  birth_year    smallint check (birth_year between 1900 and 2100),
  height_cm     numeric(4, 1) check (height_cm between 50 and 260),
  weight_kg     numeric(4, 1) check (weight_kg between 20 and 400),
  goal          text check (goal in ('lose_fat', 'gain_muscle', 'maintain')),
  conditions    text[] not null default '{}' check (
    conditions <@ array[
      'diabetes', 'hypertension', 'heart_disease', 'gout',
      'stomach', 'joint_pain', 'asthma', 'food_allergy'
    ]::text[]
  ),
  target_kcal   integer check (target_kcal between 800 and 6000),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "profiles: owner reads" on public.profiles;
create policy "profiles: owner reads" on public.profiles
  for select to anon
  using (id = public.firebase_uid());

drop policy if exists "profiles: owner creates" on public.profiles;
create policy "profiles: owner creates" on public.profiles
  for insert to anon
  with check (id = public.firebase_uid());

drop policy if exists "profiles: owner updates" on public.profiles;
create policy "profiles: owner updates" on public.profiles
  for update to anon
  using (id = public.firebase_uid())
  with check (id = public.firebase_uid());

-- Không có policy delete: xóa Tài khoản là việc của đợt sau.

-- ---------------------------------------------------------------------------
-- Kho ảnh. Mỗi file nằm trong thư mục mang UID của chủ: <uid>/<tên file>
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 2097152,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('moment-photos', 'moment-photos', false, 8388608,
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do nothing;

-- Ảnh đại diện: ai đã đăng nhập cũng xem được, chỉ chủ được ghi.
drop policy if exists "avatars: signed-in reads" on storage.objects;
create policy "avatars: signed-in reads" on storage.objects
  for select to anon
  using (bucket_id = 'avatars' and public.firebase_uid() is not null);

drop policy if exists "avatars: owner inserts" on storage.objects;
create policy "avatars: owner inserts" on storage.objects
  for insert to anon
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = public.firebase_uid());

drop policy if exists "avatars: owner updates" on storage.objects;
create policy "avatars: owner updates" on storage.objects
  for update to anon
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = public.firebase_uid())
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = public.firebase_uid());

drop policy if exists "avatars: owner deletes" on storage.objects;
create policy "avatars: owner deletes" on storage.objects
  for delete to anon
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = public.firebase_uid());

-- Ảnh Khoảnh khắc: tạm thời chỉ chủ đọc/ghi. Chia sẻ cho bạn bè làm cùng Feed.
drop policy if exists "moment-photos: owner reads" on storage.objects;
create policy "moment-photos: owner reads" on storage.objects
  for select to anon
  using (bucket_id = 'moment-photos' and (storage.foldername(name))[1] = public.firebase_uid());

drop policy if exists "moment-photos: owner inserts" on storage.objects;
create policy "moment-photos: owner inserts" on storage.objects
  for insert to anon
  with check (bucket_id = 'moment-photos' and (storage.foldername(name))[1] = public.firebase_uid());

drop policy if exists "moment-photos: owner updates" on storage.objects;
create policy "moment-photos: owner updates" on storage.objects
  for update to anon
  using (bucket_id = 'moment-photos' and (storage.foldername(name))[1] = public.firebase_uid())
  with check (bucket_id = 'moment-photos' and (storage.foldername(name))[1] = public.firebase_uid());

drop policy if exists "moment-photos: owner deletes" on storage.objects;
create policy "moment-photos: owner deletes" on storage.objects
  for delete to anon
  using (bucket_id = 'moment-photos' and (storage.foldername(name))[1] = public.firebase_uid());
