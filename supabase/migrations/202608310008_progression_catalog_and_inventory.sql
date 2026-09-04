-- Janosos V6 phase 4: canonical progression content and permanent inventory.

create table public.stat_catalog (
  id text primary key check (id in ('speed', 'jump', 'damage', 'vitality', 'fortune')),
  display_name text not null unique,
  description text not null,
  max_rank smallint not null default 5 check (max_rank = 5),
  sort_order smallint not null unique check (sort_order between 1 and 5),
  content_version text not null default 'v6-preview-1',
  enabled boolean not null default true
);

create table public.stat_rank_catalog (
  stat_id text not null references public.stat_catalog(id),
  rank smallint not null check (rank between 1 and 5),
  cost bigint not null check (cost between 1 and 1000000),
  mastery_level_required smallint not null check (
    mastery_level_required between 0 and 30
  ),
  bonus_basis_points integer not null default 0 check (
    bonus_basis_points between 0 and 10000
  ),
  bonus_lives smallint not null default 0 check (bonus_lives between 0 and 1),
  primary key (stat_id, rank)
);

insert into public.stat_catalog (
  id, display_name, description, sort_order
) values
  ('speed', 'Velocidad', 'Hasta +10% de cadencia, movimiento de boss y recuperación; nunca acelera el mundo.', 1),
  ('jump', 'Salto', 'Hasta +10% de impulso de salto.', 2),
  ('damage', 'Daño', 'Hasta +50% de daño contra enemigos y bosses.', 3),
  ('vitality', 'Vitalidad', 'Mejora la invulnerabilidad tras daño y culmina en una vida adicional.', 4),
  ('fortune', 'Fortuna', 'Hasta +15% de moneda del personaje en Progresión.', 5);

insert into public.stat_rank_catalog (
  stat_id, rank, cost, mastery_level_required, bonus_basis_points, bonus_lives
)
select stat_id, rank, cost, mastery_level, bonus, bonus_lives
from (values
  ('speed', 1::smallint, 200::bigint, 1::smallint, 200, 0::smallint),
  ('speed', 2, 450, 4, 400, 0),
  ('speed', 3, 800, 8, 600, 0),
  ('speed', 4, 1250, 14, 800, 0),
  ('speed', 5, 1800, 22, 1000, 0),
  ('jump', 1, 200, 1, 200, 0),
  ('jump', 2, 450, 4, 400, 0),
  ('jump', 3, 800, 8, 600, 0),
  ('jump', 4, 1250, 14, 800, 0),
  ('jump', 5, 1800, 22, 1000, 0),
  ('damage', 1, 250, 1, 1000, 0),
  ('damage', 2, 500, 4, 2000, 0),
  ('damage', 3, 900, 8, 3000, 0),
  ('damage', 4, 1400, 14, 4000, 0),
  ('damage', 5, 2000, 22, 5000, 0),
  ('vitality', 1, 300, 2, 200, 0),
  ('vitality', 2, 600, 6, 400, 0),
  ('vitality', 3, 1000, 10, 600, 0),
  ('vitality', 4, 1600, 16, 800, 0),
  ('vitality', 5, 2400, 24, 1000, 1),
  ('fortune', 1, 250, 2, 300, 0),
  ('fortune', 2, 550, 6, 600, 0),
  ('fortune', 3, 950, 10, 900, 0),
  ('fortune', 4, 1500, 16, 1200, 0),
  ('fortune', 5, 2200, 24, 1500, 0)
) as ranks(stat_id, rank, cost, mastery_level, bonus, bonus_lives);

create table public.mastery_baseline_catalog (
  mastery_level smallint not null check (mastery_level between 1 and 30),
  stat_id text not null references public.stat_catalog(id),
  bonus_basis_points integer not null check (bonus_basis_points between 1 and 1000),
  content_version text not null default 'v6-preview-1',
  primary key (mastery_level, stat_id)
);

insert into public.mastery_baseline_catalog (
  mastery_level, stat_id, bonus_basis_points
) values
  (3, 'speed', 100),
  (6, 'jump', 100),
  (9, 'damage', 500),
  (12, 'fortune', 100),
  (18, 'speed', 100),
  (22, 'jump', 100),
  (26, 'damage', 500),
  (30, 'fortune', 200);

create table public.skill_catalog (
  id text primary key check (id ~ '^[a-z][a-z0-9_]{2,63}$'),
  character_id text not null references public.characters(id),
  slot text not null check (slot in ('active', 'passive')),
  display_name text not null,
  description text not null,
  unlock_level smallint not null check (unlock_level between 1 and 30),
  cost bigint not null check (cost between 1 and 1000000),
  effect_code text not null check (effect_code ~ '^[a-z][a-z0-9_]{2,63}$'),
  effect_parameters jsonb not null check (jsonb_typeof(effect_parameters) = 'object'),
  compatible_modes public.game_mode[] not null default array[
    'progression'::public.game_mode,
    'boss_rush'::public.game_mode
  ] check (
    compatible_modes = array[
      'progression'::public.game_mode,
      'boss_rush'::public.game_mode
    ]
  ),
  ui_explanation text not null,
  sort_order smallint not null check (sort_order between 1 and 4),
  content_version text not null default 'v6-preview-1',
  enabled boolean not null default true,
  unique (id, character_id),
  unique (character_id, sort_order)
);

insert into public.skill_catalog (
  id, character_id, slot, display_name, description, unlock_level, cost,
  effect_code, effect_parameters, ui_explanation, sort_order
) values
  ('jano_ricochet_round', 'jano', 'active', 'Bala de rebote', 'El siguiente disparo rebota una vez hacia el objetivo válido más cercano.', 5, 1200, 'ricochet_projectile', '{"max_bounces":1,"damage_basis_points":8000}', 'Un rebote; el segundo impacto causa 80% del daño base.', 1),
  ('jano_burst_protocol', 'jano', 'active', 'Protocolo ráfaga', 'Dispara tres proyectiles de menor potencia con una sola activación.', 14, 3200, 'projectile_burst', '{"projectiles":3,"damage_basis_points":4500}', 'Tres tiros al 45% cada uno; comparte el cooldown del disparo.', 2),
  ('jano_quickdraw', 'jano', 'passive', 'Desenfunde', 'Reduce de forma limitada la recuperación de habilidades de proyectil.', 8, 1800, 'cooldown_reduction', '{"basis_points":1000,"ability_family":"projectile"}', '10% menos cooldown; no afecta la velocidad del mundo.', 3),
  ('jano_scavenger_sight', 'jano', 'passive', 'Mira oportunista', 'Los impactos precisos conceden una bonificación de puntuación con límite por encuentro.', 20, 4200, 'precision_score_bonus', '{"basis_points":500,"encounter_cap":500}', '+5% por impacto válido, hasta 500 puntos por encuentro.', 4),

  ('parker_guard_dash', 'parker', 'active', 'Embestida guardiana', 'Una carrera breve que ignora un impacto frontal sin consumir la vida extra innata.', 5, 1200, 'guard_dash', '{"duration_ms":450,"cooldown_ms":12000}', 'Protege sólo durante 450 ms y no repone vidas.', 1),
  ('parker_rally', 'parker', 'active', 'Último aliento', 'Al quedar en la última vida, activa una recuperación corta una vez por nivel.', 14, 3200, 'last_life_rally', '{"duration_ms":2500,"uses_per_stage":1}', 'Una vez por nivel; no evita un impacto ni añade vidas.', 2),
  ('parker_reinforced_vest', 'parker', 'passive', 'Chaleco reforzado', 'Extiende ligeramente la invulnerabilidad posterior a recibir daño.', 8, 1800, 'post_hit_invulnerability', '{"basis_points":1000}', '+10% de ventana tras daño; sigue consumiendo una vida.', 3),
  ('parker_second_wind', 'parker', 'passive', 'Segundo aire', 'Mejora temporalmente la recuperación tras perder una vida.', 20, 4200, 'recovery_after_life_loss', '{"basis_points":1000,"duration_ms":4000}', '+10% de recuperación durante 4 s; no restaura la vida.', 4),

  ('chema_shield_pulse', 'chema', 'active', 'Pulso de escudo', 'Emite un pulso que daña amenazas cercanas sin reemplazar su escudo innato.', 5, 1200, 'shield_pulse', '{"radius":180,"damage_basis_points":6000,"cooldown_ms":12000}', 'Daño de área al 60%; no reinicia la regeneración del escudo.', 1),
  ('chema_debt_discharge', 'chema', 'active', 'Descarga de deuda', 'Convierte una parte de la penalización reciente del escudo en daño contra el boss.', 14, 3200, 'penalty_discharge', '{"conversion_basis_points":5000,"stage_cap":750}', 'Convierte 50% con tope de 750 por nivel; la penalización original permanece.', 2),
  ('chema_capacitor', 'chema', 'passive', 'Capacitor estable', 'Reduce de forma limitada el tiempo de regeneración del escudo innato.', 8, 1800, 'shield_regeneration', '{"basis_points":1000}', '10% menos espera; nunca concede dos escudos simultáneos.', 3),
  ('chema_score_insurance', 'chema', 'passive', 'Seguro de puntos', 'Reduce parte de la penalización de puntuación al romperse el escudo.', 20, 4200, 'shield_penalty_reduction', '{"basis_points":2000}', 'Reduce la penalización 20%; no puede convertirla en recompensa.', 4),

  ('conra_phase_dash', 'conra', 'active', 'Paso espectral', 'Avanza una distancia fija en fase y vuelve a ser tangible al terminar.', 5, 1200, 'phase_dash', '{"distance":160,"duration_ms":350,"cooldown_ms":12000}', 'Fase de 350 ms; no atraviesa límites del encuentro.', 1),
  ('conra_spectral_decoy', 'conra', 'active', 'Señuelo espectral', 'Crea un señuelo breve que atrae un ataque dirigido del boss.', 14, 3200, 'spectral_decoy', '{"duration_ms":1800,"uses_per_stage":2}', 'Hasta dos usos por nivel; no elimina ataques de área.', 2),
  ('conra_lingering_veil', 'conra', 'passive', 'Velo persistente', 'Extiende moderadamente la intangibilidad predeterminada.', 8, 1800, 'intangibility_duration', '{"basis_points":1000}', '+10% de duración; conserva el cooldown original modificado por stats.', 3),
  ('conra_phase_reserve', 'conra', 'passive', 'Reserva de fase', 'Tras salir de fase obtiene una protección mínima contra el primer contacto.', 20, 4200, 'phase_exit_grace', '{"duration_ms":300}', '300 ms de gracia; no bloquea proyectiles del boss.', 4),

  ('shyno_aerial_stomp', 'shyno', 'active', 'Pisotón aéreo', 'Desciende con fuerza y causa daño al aterrizar.', 5, 1200, 'aerial_stomp', '{"radius":150,"damage_basis_points":7000,"cooldown_ms":10000}', 'Daño de área al 70%; exige estar en el aire.', 1),
  ('shyno_wind_burst', 'shyno', 'active', 'Ráfaga ascendente', 'Recupera una pequeña elevación sin conceder un tercer salto permanente.', 14, 3200, 'vertical_burst', '{"impulse_basis_points":4500,"cooldown_ms":14000}', '45% del impulso base; no reinicia el doble salto.', 2),
  ('shyno_spring_heels', 'shyno', 'passive', 'Talones de resorte', 'Mejora ligeramente el control horizontal durante el segundo salto.', 8, 1800, 'double_jump_control', '{"basis_points":1000}', '+10% de control sólo durante el segundo salto.', 3),
  ('shyno_landing_rhythm', 'shyno', 'passive', 'Ritmo de aterrizaje', 'Una caída precisa reduce el próximo cooldown activo.', 20, 4200, 'precision_landing_cooldown', '{"reduction_ms":800,"minimum_cooldown_ms":4000}', 'Reduce hasta 0.8 s; nunca baja de 4 s.', 4),

  ('nakama_tailwind', 'nakama', 'active', 'Viento de cola', 'Genera un impulso horizontal breve mientras planea.', 5, 1200, 'glide_tailwind', '{"duration_ms":900,"speed_basis_points":1200,"cooldown_ms":12000}', '+12% durante 0.9 s sólo al planear; no acelera el mundo.', 1),
  ('nakama_feather_guard', 'nakama', 'active', 'Guardia de plumas', 'Amortigua un proyectil durante el planeo y termina inmediatamente el efecto.', 14, 3200, 'glide_projectile_guard', '{"uses_per_stage":1,"duration_ms":1600}', 'Un proyectil por nivel; no bloquea colisiones ni ataques de área.', 2),
  ('nakama_thermal_lift', 'nakama', 'passive', 'Corriente térmica', 'Reduce aún más la caída durante la primera parte del planeo.', 8, 1800, 'glide_fall_reduction', '{"basis_points":1000,"duration_ms":1200}', '+10% durante 1.2 s; respeta la altura máxima del encuentro.', 3),
  ('nakama_soft_landing', 'nakama', 'passive', 'Aterrizaje suave', 'Concede una breve recuperación al tocar tierra después de planear.', 20, 4200, 'glide_landing_recovery', '{"basis_points":1000,"duration_ms":2000}', '+10% de recuperación durante 2 s; sin inmunidad.', 4),

  ('nanic_arc_burst', 'nanic', 'active', 'Arco voltaico', 'Consume la carga para encadenar daño entre dos objetivos válidos.', 5, 1200, 'electric_chain', '{"targets":2,"damage_basis_points":6500}', 'Hasta dos objetivos al 65%; consume la carga completa.', 1),
  ('nanic_overclock', 'nanic', 'active', 'Sobrecarga', 'Consume la carga para potenciar temporalmente cadencia y daño.', 14, 3200, 'energy_overclock', '{"duration_ms":3000,"speed_basis_points":1000,"damage_basis_points":1000}', '+10% de cadencia y daño durante 3 s; consume la carga completa.', 2),
  ('nanic_efficient_charge', 'nanic', 'passive', 'Carga eficiente', 'Cada nivel permite que el primer orbe cuente doble.', 8, 1800, 'first_orb_double_charge', '{"uses_per_stage":1}', 'Sólo el primer orbe de cada nivel; no altera la recompensa del orbe.', 3),
  ('nanic_residual_field', 'nanic', 'passive', 'Campo residual', 'Tras descargar energía conserva una protección muy breve.', 20, 4200, 'discharge_grace', '{"duration_ms":350}', '350 ms de gracia; no destruye un segundo obstáculo.', 4);

create table public.skin_catalog (
  id text primary key check (id ~ '^[a-z][a-z0-9_]{2,63}$'),
  character_id text not null references public.characters(id),
  display_name text not null,
  asset_model text not null default 'palette' check (
    asset_model in ('palette', 'sprite_sheet')
  ),
  palette_parameters jsonb not null check (
    jsonb_typeof(palette_parameters) = 'object'
    and palette_parameters ?& array[
      'hue_shift', 'saturation_basis_points', 'value_basis_points'
    ]
    and jsonb_typeof(palette_parameters -> 'hue_shift') = 'number'
    and jsonb_typeof(palette_parameters -> 'saturation_basis_points') = 'number'
    and jsonb_typeof(palette_parameters -> 'value_basis_points') = 'number'
    and (palette_parameters ->> 'hue_shift')::integer between 0 and 359
    and (palette_parameters ->> 'saturation_basis_points')::integer
      between 5000 and 15000
    and (palette_parameters ->> 'value_basis_points')::integer
      between 5000 and 15000
  ),
  unlock_level smallint not null check (unlock_level between 0 and 30),
  cost bigint not null check (cost between 0 and 1000000),
  future_premium_sku text,
  available_in_v6 boolean not null default true,
  sort_order smallint not null check (sort_order between 0 and 20),
  content_version text not null default 'v6-preview-1',
  unique (id, character_id),
  unique (character_id, sort_order),
  check (not available_in_v6 or future_premium_sku is null),
  check (asset_model = 'palette' or not available_in_v6)
);

insert into public.skin_catalog (
  id, character_id, display_name, palette_parameters,
  unlock_level, cost, sort_order
)
select
  character.id || '_default', character.id, 'Original',
  '{"hue_shift":0,"saturation_basis_points":10000,"value_basis_points":10000}'::jsonb,
  0, 0, 0
from public.characters as character
union all
select
  character.id || '_aurora', character.id, 'Aurora',
  '{"hue_shift":55,"saturation_basis_points":11200,"value_basis_points":10800}'::jsonb,
  3, 800, 1
from public.characters as character
union all
select
  character.id || '_eclipse', character.id, 'Eclipse',
  '{"hue_shift":210,"saturation_basis_points":9000,"value_basis_points":7800}'::jsonb,
  10, 1800, 2
from public.characters as character;

create table public.stat_upgrades (
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  stat_id text not null references public.stat_catalog(id),
  purchased_rank smallint not null check (purchased_rank between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, character_id, stat_id)
);

create table public.skill_unlocks (
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  skill_id text not null,
  source text not null check (source in ('purchase', 'boss_drop', 'grant')),
  acquired_at timestamptz not null default now(),
  primary key (user_id, character_id, skill_id),
  foreign key (skill_id, character_id)
    references public.skill_catalog(id, character_id)
);

create table public.skin_unlocks (
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  skin_id text not null,
  source text not null check (source in ('purchase', 'boss_drop', 'grant')),
  acquired_at timestamptz not null default now(),
  primary key (user_id, character_id, skin_id),
  foreign key (skin_id, character_id)
    references public.skin_catalog(id, character_id)
);

create table public.loadouts (
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  active_skill_id text,
  passive_skill_1_id text,
  passive_skill_2_id text,
  skin_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, character_id),
  foreign key (active_skill_id, character_id)
    references public.skill_catalog(id, character_id),
  foreign key (passive_skill_1_id, character_id)
    references public.skill_catalog(id, character_id),
  foreign key (passive_skill_2_id, character_id)
    references public.skill_catalog(id, character_id),
  foreign key (skin_id, character_id)
    references public.skin_catalog(id, character_id),
  check (
    passive_skill_1_id is null
    or passive_skill_2_id is null
    or passive_skill_1_id <> passive_skill_2_id
  )
);

create table public.boss_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  character_id text not null references public.characters(id),
  boss_level smallint not null check (boss_level between 1 and 10),
  victories integer not null default 0 check (victories >= 0),
  unique_reward_id text,
  unique_reward_owned boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, character_id, boss_level),
  check (not unique_reward_owned or unique_reward_id is not null)
);

create index stat_upgrades_owner on public.stat_upgrades (user_id, character_id);
create index skill_unlocks_owner on public.skill_unlocks (user_id, character_id);
create index skin_unlocks_owner on public.skin_unlocks (user_id, character_id);
create index boss_progress_owner on public.boss_progress (user_id, character_id);

create trigger stat_upgrades_touch_updated_at
before update on public.stat_upgrades
for each row execute function private.touch_updated_at();

create trigger loadouts_touch_updated_at
before update on public.loadouts
for each row execute function private.touch_updated_at();

create trigger boss_progress_touch_updated_at
before update on public.boss_progress
for each row execute function private.touch_updated_at();

create or replace function private.compute_progression_catalog_digest(
  p_content_version text
)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  with catalog_lines as (
    select format(
      'stat|%s|%s|%s|%s|%s|%s',
      rank.stat_id, rank.rank, rank.cost, rank.mastery_level_required,
      rank.bonus_basis_points, rank.bonus_lives
    ) as line
    from public.stat_rank_catalog as rank
    join public.stat_catalog as stat on stat.id = rank.stat_id
    where stat.content_version = p_content_version and stat.enabled
    union all
    select format(
      'baseline|%s|%s|%s', baseline.mastery_level,
      baseline.stat_id, baseline.bonus_basis_points
    )
    from public.mastery_baseline_catalog as baseline
    where baseline.content_version = p_content_version
    union all
    select format(
      'skill|%s|%s|%s|%s|%s|%s|%s',
      skill.id, skill.character_id, skill.slot, skill.unlock_level,
      skill.cost, skill.effect_code, skill.effect_parameters::text
    )
    from public.skill_catalog as skill
    where skill.content_version = p_content_version and skill.enabled
    union all
    select format(
      'skin|%s|%s|%s|%s|%s|%s',
      skin.id, skin.character_id, skin.asset_model, skin.unlock_level,
      skin.cost, skin.palette_parameters::text
    )
    from public.skin_catalog as skin
    where skin.content_version = p_content_version and skin.available_in_v6
  )
  select encode(
    extensions.digest(
      convert_to(coalesce(string_agg(line, E'\n' order by line), ''), 'UTF8'),
      'sha256'
    ),
    'hex'
  )
  from catalog_lines;
$$;

create table public.content_manifests (
  content_version text primary key,
  catalog_digest text not null check (catalog_digest ~ '^[0-9a-f]{64}$'),
  generated_at timestamptz not null default now(),
  active boolean not null default true
);

insert into public.content_manifests (content_version, catalog_digest)
values (
  'v6-preview-1',
  private.compute_progression_catalog_digest('v6-preview-1')
);

comment on table public.skill_catalog is
  'Twenty-eight exclusive purchasable skills; existing character identity is not sold.';
comment on column public.skin_catalog.future_premium_sku is
  'Future seam only. Every V6-visible palette must keep this null.';
comment on table public.content_manifests is
  'Digest pins the canonical gameplay catalog used by economic commands.';

revoke all on function private.compute_progression_catalog_digest(text)
from public, anon, authenticated;
grant execute on function private.compute_progression_catalog_digest(text)
to service_role;
