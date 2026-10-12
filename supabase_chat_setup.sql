-- ============================================
-- Mohammed Store - Supabase Chat Setup
-- Firebase Authentication + Supabase Chat
-- ============================================

-- صلاحيات القراءة والكتابة الأساسية للتطبيق
grant usage on schema public to anon;

grant select, insert, update
on table public.conversations
to anon;

grant select, insert, update
on table public.messages
to anon;


-- ============================================
-- إضافة العمود المطلوب إن لم يكن موجودًا
-- ============================================

alter table public.conversations
add column if not exists last_message_sender_id text;


-- ============================================
-- دالة حذف المحادثة ورسائلها
-- ============================================

create or replace function public.delete_conversation_for_admin(
  p_chat_id text,
  p_admin_uid text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin

  -- السماح للأدمن المحدد فقط
  if p_admin_uid <> 'QHMQtobX65V64nIyxNUkGSybvEB3' then
    raise exception 'admin permission required';
  end if;

  -- حذف رسائل المحادثة
  delete from public.messages
  where conversation_id::text = p_chat_id;

  -- حذف المحادثة نفسها
  delete from public.conversations
  where id::text = p_chat_id;

  -- التأكد أن المحادثة كانت موجودة
  if not found then
    raise exception 'conversation not found';
  end if;

end;
$$;


-- ============================================
-- صلاحيات دالة الحذف
-- ============================================

revoke all
on function public.delete_conversation_for_admin(text, text)
from public;

grant execute
on function public.delete_conversation_for_admin(text, text)
to anon;


-- ============================================
-- تفعيل Realtime بدون تكرار الإضافة
-- ============================================

do $$
begin

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'conversations'
  ) then

    alter publication supabase_realtime
    add table public.conversations;

  end if;


  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then

    alter publication supabase_realtime
    add table public.messages;

  end if;

end
$$;


-- ============================================
-- التحقق من وجود الدالة
-- ============================================

select
  routine_name,
  routine_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name = 'delete_conversation_for_admin';
