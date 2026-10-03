-- Migración 2: Bloqueos de pista por administradores, RPC atómicas y optimizaciones de seguridad

-- Tabla de bloqueos de pista (mantenimiento, obras, torneos comunitarios, etc.)
create table if not exists public.court_blocks (
  id uuid primary key default uuid_generate_v4(),
  created_by uuid references public.profiles(id) on delete set null,
  reason text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz not null default now(),

  constraint block_start_before_end check (start_time < end_time),
  constraint block_valid_minutes check (
    extract(minute from start_time) in (0, 30) and
    extract(second from start_time) = 0 and
    extract(minute from end_time) in (0, 30) and
    extract(second from end_time) = 0
  )
);

-- Prevenir solapamiento entre bloqueos
alter table public.court_blocks
  add constraint no_overlapping_blocks
  exclude using gist (
    tstzrange(start_time, end_time) with &&
  );

-- Habilitar RLS en court_blocks
alter table public.court_blocks enable row level security;

create policy "Cualquier usuario autenticado puede ver los bloqueos de pista"
  on public.court_blocks for select
  to authenticated
  using (true);

create policy "Solo los administradores pueden gestionar bloqueos"
  on public.court_blocks for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Actualizar la validación de reservas para comprobar que no se solape con bloqueos
create or replace function public.validate_reservation()
returns trigger as $$
declare
  v_user_status user_status;
  v_user_block text;
  v_user_floor text;
  v_user_door text;
  v_total_minutes integer;
  v_target_date date;
  v_has_block boolean;
begin
  -- 1. Obtener datos y estado del usuario desde el perfil
  select status, block, floor, door
  into v_user_status, v_user_block, v_user_floor, v_user_door
  from public.profiles
  where id = new.user_id;

  if not found then
    raise exception 'El perfil del usuario no existe.';
  end if;

  -- 2. Usuarios revocados no pueden reservar
  if v_user_status = 'revoked' then
    raise exception 'El usuario está revocado y no tiene permisos para reservar.';
  end if;

  -- Asignar la vivienda desde el perfil garantizando integridad
  new.block := v_user_block;
  new.floor := v_user_floor;
  new.door := v_user_door;

  -- 3. No permitir reservas en el pasado
  if new.start_time < now() then
    raise exception 'No se permiten reservas en fechas u horas pasadas.';
  end if;

  -- 4. Solo reservar dentro de las próximas 24 horas a partir de este momento
  if new.start_time > (now() + interval '24 hours') then
    raise exception 'Solo se permiten reservas dentro de las próximas 24 horas.';
  end if;

  -- 5. Validar que no haya bloqueos de pista (obras, mantenimiento, etc.)
  select exists (
    select 1 from public.court_blocks
    where tstzrange(start_time, end_time) && tstzrange(new.start_time, new.end_time)
  ) into v_has_block;

  if v_has_block then
    raise exception 'La pista está bloqueada por administración durante ese horario.';
  end if;

  -- 6. Límite diario de 120 minutos por vivienda al día
  v_target_date := (new.start_time at time zone 'Europe/Madrid')::date;

  select coalesce(sum(extract(epoch from (end_time - start_time)) / 60), 0)
  into v_total_minutes
  from public.reservations
  where block = new.block
    and floor = new.floor
    and door = new.door
    and (start_time at time zone 'Europe/Madrid')::date = v_target_date
    and (tg_op = 'INSERT' or id <> new.id);

  if (v_total_minutes + (extract(epoch from (new.end_time - new.start_time)) / 60)) > 120 then
    raise exception 'Límite de 120 minutos diarios por vivienda superado para este día.';
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- ==============================================================================
-- RPCs: Procedimientos almacenados para la lógica transaccional segura
-- ==============================================================================

-- RPC: Crear reserva de forma segura
create or replace function public.create_reservation(
  p_start_time timestamptz,
  p_end_time timestamptz
)
returns public.reservations as $$
declare
  v_uid uuid;
  v_profile public.profiles%rowtype;
  v_new_res public.reservations;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Usuario no autenticado.';
  end if;

  select * into v_profile from public.profiles where id = v_uid;
  if not found then
    raise exception 'Perfil no encontrado.';
  end if;

  if v_profile.status = 'revoked' then
    raise exception 'Acceso revocado.';
  end if;

  insert into public.reservations (
    user_id,
    block,
    floor,
    door,
    start_time,
    end_time
  ) values (
    v_uid,
    v_profile.block,
    v_profile.floor,
    v_profile.door,
    p_start_time,
    p_end_time
  )
  returning * into v_new_res;

  return v_new_res;
end;
$$ language plpgsql security definer;

-- RPC: Cancelar reserva
create or replace function public.cancel_reservation(p_reservation_id uuid)
returns boolean as $$
declare
  v_uid uuid;
  v_res public.reservations;
  v_is_admin boolean;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Usuario no autenticado.';
  end if;

  select * into v_res from public.reservations where id = p_reservation_id;
  if not found then
    raise exception 'Reserva no encontrada.';
  end if;

  select public.is_admin() into v_is_admin;

  if v_res.user_id <> v_uid and not v_is_admin then
    raise exception 'No tienes permisos para cancelar esta reserva.';
  end if;

  delete from public.reservations where id = p_reservation_id;
  return true;
end;
$$ language plpgsql security definer;

-- RPC: Crear bloqueo de pista (solo admin)
create or replace function public.create_court_block(
  p_start_time timestamptz,
  p_end_time timestamptz,
  p_reason text
)
returns public.court_blocks as $$
declare
  v_uid uuid;
  v_block public.court_blocks;
begin
  v_uid := auth.uid();
  if not public.is_admin() then
    raise exception 'Solo administradores pueden bloquear la pista.';
  end if;

  -- Eliminar o verificar reservas previas en ese hueco
  delete from public.reservations
  where tstzrange(start_time, end_time) && tstzrange(p_start_time, p_end_time);

  insert into public.court_blocks (
    created_by,
    reason,
    start_time,
    end_time
  ) values (
    v_uid,
    coalesce(trim(p_reason), 'Bloqueo administrativo'),
    p_start_time,
    p_end_time
  )
  returning * into v_block;

  return v_block;
end;
$$ language plpgsql security definer;

-- RPC: Eliminar bloqueo de pista (solo admin)
create or replace function public.remove_court_block(p_block_id uuid)
returns boolean as $$
begin
  if not public.is_admin() then
    raise exception 'Solo administradores pueden eliminar bloqueos.';
  end if;

  delete from public.court_blocks where id = p_block_id;
  return true;
end;
$$ language plpgsql security definer;

-- RPC: Actualizar estado de usuario (approved / revoked) (solo admin)
create or replace function public.admin_set_user_status(
  p_user_id uuid,
  p_status user_status
)
returns boolean as $$
begin
  if not public.is_admin() then
    raise exception 'Solo administradores pueden cambiar el estado de usuarios.';
  end if;

  update public.profiles
  set status = p_status,
      updated_at = now()
  where id = p_user_id;

  return true;
end;
$$ language plpgsql security definer;

-- RPC: Corregir vivienda de usuario (solo admin)
create or replace function public.admin_update_dwelling(
  p_user_id uuid,
  p_block text,
  p_floor text,
  p_door text
)
returns boolean as $$
begin
  if not public.is_admin() then
    raise exception 'Solo administradores pueden corregir datos de vivienda.';
  end if;

  update public.profiles
  set block = p_block,
      floor = p_floor,
      door = p_door,
      updated_at = now()
  where id = p_user_id;

  return true;
end;
$$ language plpgsql security definer;

-- RPC: Obtener los slots disponibles y ocupados de las próximas 24h
create or replace function public.get_court_schedule()
returns json as $$
declare
  v_now timestamptz := now();
  v_limit timestamptz := now() + interval '24 hours';
  v_reservations json;
  v_blocks json;
begin
  select coalesce(json_agg(r), '[]'::json)
  into v_reservations
  from (
    select id, user_id, block, floor, door, start_time, end_time, created_at
    from public.reservations
    where end_time > v_now and start_time < v_limit
    order by start_time asc
  ) r;

  select coalesce(json_agg(b), '[]'::json)
  into v_blocks
  from (
    select id, reason, start_time, end_time, created_at
    from public.court_blocks
    where end_time > v_now and start_time < v_limit
    order by start_time asc
  ) b;

  return json_build_object(
    'reservations', v_reservations,
    'blocks', v_blocks,
    'server_time', v_now
  );
end;
$$ language plpgsql security definer stable;
