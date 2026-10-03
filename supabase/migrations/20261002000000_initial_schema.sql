-- Migración Inicial: Esquema de base de datos para Pádel Comunidad
-- Cumple con todas las reglas de negocio descritas en AGENT.md

-- Extensiones necesarias
create extension if not exists "uuid-ossp";
create extension if not exists "btree_gist";

-- Tipo de estados y roles
create type user_status as enum ('approved', 'revoked');
create type user_role as enum ('resident', 'admin');

-- Tabla de perfiles vinculada a auth.users
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  username text not null unique,
  email text not null unique,
  block text not null,
  floor text not null,
  door text not null,
  status user_status not null default 'approved',
  role user_role not null default 'resident',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Tabla de reservas de la pista única de pádel
create table public.reservations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  block text not null,
  floor text not null,
  door text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz not null default now(),

  -- Restricción básica de coherencia temporal
  constraint reservation_start_before_end check (start_time < end_time),

  -- Intervalos múltiplos exactos de 30 minutos (segundos = 0 y minutos en 0 o 30)
  constraint reservation_valid_minutes check (
    extract(minute from start_time) in (0, 30) and
    extract(second from start_time) = 0 and
    extract(minute from end_time) in (0, 30) and
    extract(second from end_time) = 0
  ),

  -- Duración mínima 30 minutos, máxima 120 minutos
  constraint reservation_duration_check check (
    end_time - start_time >= interval '30 minutes' and
    end_time - start_time <= interval '120 minutes'
  )
);

-- Prevenir solapamientos concurrentes y consistentes en la única pista usando exclusión GiST
alter table public.reservations
  add constraint no_overlapping_reservations
  exclude using gist (
    tstzrange(start_time, end_time) with &&
  );

-- Índices para búsquedas eficientes
create index idx_reservations_start_time on public.reservations(start_time);
create index idx_reservations_dwelling on public.reservations(block, floor, door, start_time);
create index idx_profiles_username on public.profiles(username);

-- Función y Trigger para mantener updated_at en profiles
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_profiles_updated
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- Función de validación de negocio antes de insertar una reserva
create or replace function public.validate_reservation()
returns trigger as $$
declare
  v_user_status user_status;
  v_user_block text;
  v_user_floor text;
  v_user_door text;
  v_total_minutes integer;
  v_target_date date;
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

  -- 5. Límite diario de 120 minutos por vivienda al día
  -- Evaluamos el día local de inicio de la reserva
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

create trigger trigger_validate_reservation
  before insert or update on public.reservations
  for each row execute function public.validate_reservation();

-- Función para manejar nuevos registros en auth.users y crear el profile
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (
    id,
    full_name,
    username,
    email,
    block,
    floor,
    door,
    status,
    role
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'block', ''),
    coalesce(new.raw_user_meta_data->>'floor', ''),
    coalesce(new.raw_user_meta_data->>'door', ''),
    'approved',
    'resident'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Habilitar RLS (Row Level Security)
alter table public.profiles enable row level security;
alter table public.reservations enable row level security;

-- Función auxiliar segura para consultar rol del usuario actual
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
end;
$$ language plpgsql security definer stable;

-- Políticas RLS para Profiles
create policy "Los usuarios autenticados pueden ver todos los perfiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Los usuarios pueden actualizar únicamente su propio nombre"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (
    auth.uid() = id and
    role = (select role from public.profiles where id = auth.uid()) and
    status = (select status from public.profiles where id = auth.uid())
  );

create policy "Administradores tienen control total sobre perfiles"
  on public.profiles for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Políticas RLS para Reservations
create policy "Cualquier usuario autenticado puede ver las reservas"
  on public.reservations for select
  to authenticated
  using (true);

create policy "Los usuarios aprobados pueden crear sus reservas"
  on public.reservations for insert
  to authenticated
  with check (
    auth.uid() = user_id and
    exists (
      select 1 from public.profiles
      where id = auth.uid() and status = 'approved'
    )
  );

create policy "Los usuarios pueden cancelar sus propias reservas o los administradores"
  on public.reservations for delete
  to authenticated
  using (
    auth.uid() = user_id or public.is_admin()
  );
