-- قاعدة بيانات مساعد BCBA الذكي (Supabase)
-- الصقي هذا الملف كاملًا في: Supabase > SQL Editor > New query > Run

create table if not exists public.records (
  collection text not null,              -- meta / sessions / events / sources
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (collection, id)
);

alter table public.records enable row level security;

-- لا يقرأ ولا يكتب إلا من سجّل دخوله بحساب أنشأته المشرفة
drop policy if exists "team read"   on public.records;
drop policy if exists "team insert" on public.records;
drop policy if exists "team update" on public.records;
drop policy if exists "team delete" on public.records;
create policy "team read"   on public.records for select to authenticated using (true);
create policy "team insert" on public.records for insert to authenticated with check (true);
create policy "team update" on public.records for update to authenticated using (true) with check (true);
create policy "team delete" on public.records for delete to authenticated using (true);

create or replace function public.records_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists records_touch on public.records;
create trigger records_touch before insert or update on public.records
for each row execute function public.records_touch();

-- صلاحيات الجدول لمستخدمي الفريق المسجّلين فقط
revoke all on public.records from anon;
grant select, insert, update, delete on public.records to authenticated;
