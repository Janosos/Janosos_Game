-- Migration: 202609070014_unlock_store_by_default.sql
-- Habilita la tienda arcade y compra de mejoras desde el inicio en Supabase

alter table public.character_progress
  alter column purchase_phase_unlocked set default true;

update public.character_progress
  set purchase_phase_unlocked = true;
