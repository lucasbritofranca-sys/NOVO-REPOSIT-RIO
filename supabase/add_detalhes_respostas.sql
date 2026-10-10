-- Adiciona suporte a medições/campos complementares nas respostas do checklist.
-- Execute uma vez no SQL Editor se o schema.sql já tiver sido aplicado ao projeto.

alter table public.respostas_inspecao
  add column if not exists detalhes jsonb not null default '{}'::jsonb;
