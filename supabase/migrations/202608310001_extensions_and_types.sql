-- Janosos V6 phase 3: shared database types for server-authorized runs.

create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;

create type public.game_mode as enum (
  'standard',
  'progression',
  'boss_rush'
);

create type public.campaign_state as enum (
  'active',
  'completed',
  'failed',
  'abandoned',
  'expired'
);

create type public.stage_status as enum (
  'token_issued',
  'playing',
  'finished_pending',
  'accepted',
  'rejected'
);

create type public.run_outcome as enum ('victory', 'defeat');

create type public.validation_status as enum (
  'pending',
  'verified',
  'limited',
  'rejected'
);

create type public.command_status as enum (
  'processing',
  'accepted',
  'limited',
  'rejected'
);

