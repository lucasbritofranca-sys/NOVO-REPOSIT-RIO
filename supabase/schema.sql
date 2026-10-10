-- Esquema inicial para o checklist de inspeção de frota.
-- Execute no SQL Editor do Supabase. As políticas assumem usuários autenticados.

create extension if not exists pgcrypto;

create type public.tipo_equipamento as enum ('caminhao', 'maquina', 'apoio');
create type public.situacao_inspecao as enum ('liberado', 'requer_avaliacao', 'bloqueado');
create type public.situacao_resposta as enum ('ok', 'nc', 'na');
create type public.prioridade_risco as enum ('critica', 'alta', 'media', 'baixa');

-- Cadastro opcional de equipamentos. O prefixo é único dentro da unidade.
create table public.equipamentos (
  id uuid primary key default gen_random_uuid(),
  unidade text not null,
  codigo_patrimonio text not null,
  tipo public.tipo_equipamento not null,
  nome_modelo text,
  criado_por uuid not null default auth.uid() references auth.users(id) on delete restrict,
  criado_em timestamptz not null default now(),
  unique (unidade, codigo_patrimonio)
);

-- Registro principal da inspeção: campos da identificação e confirmação.
create table public.inspecoes (
  id uuid primary key default gen_random_uuid(),
  criado_por uuid not null default auth.uid() references auth.users(id) on delete restrict,
  unidade text not null,
  data_inspecao date not null,
  turno text not null,
  tipo_equipamento public.tipo_equipamento not null,
  equipamento_id uuid references public.equipamentos(id) on delete set null,
  equipamento_nome text,
  codigo_patrimonio text not null,
  leitura_horimetro_odometro numeric(12, 2),
  unidade_medicao text, -- horímetro ou odômetro; a tela atual não especifica qual.
  nome_operador text not null,
  nome_inspetor text,
  situacao public.situacao_inspecao not null,
  confirmada boolean not null default false check (confirmada),
  concluida_em timestamptz not null default now(),
  observacoes_gerais text,
  criada_em timestamptz not null default now()
);

-- Uma linha por item apresentado no checklist, incluindo OK, NC e N/A.
-- item_code identifica o item; item_label preserva o texto exibido na data da inspeção.
create table public.respostas_inspecao (
  id uuid primary key default gen_random_uuid(),
  inspecao_id uuid not null references public.inspecoes(id) on delete cascade,
  codigo_item text not null,
  descricao_item text not null,
  secao text not null, -- comuns, caminhao, maquina, apoio ou funcional
  resposta public.situacao_resposta not null,
  detalhes jsonb not null default '{}'::jsonb,
  criada_em timestamptz not null default now(),
  unique (inspecao_id, codigo_item)
);

-- Detalhes preenchidos quando a resposta é NC.
create table public.nao_conformidades (
  id uuid primary key default gen_random_uuid(),
  resposta_id uuid not null unique references public.respostas_inspecao(id) on delete cascade,
  descricao_defeito text not null,
  prioridade_risco public.prioridade_risco not null,
  acao_tomada text,
  responsavel_comunicado text,
  equipamento_liberado boolean,
  criada_em timestamptz not null default now()
);

create index inspecoes_criado_por_data_idx
  on public.inspecoes (criado_por, data_inspecao desc, concluida_em desc);
create index inspecoes_unidade_patrimonio_idx
  on public.inspecoes (unidade, codigo_patrimonio, data_inspecao desc);
create index respostas_inspecao_inspecao_idx
  on public.respostas_inspecao (inspecao_id);
create index nao_conformidades_prioridade_idx
  on public.nao_conformidades (prioridade_risco);

alter table public.equipamentos enable row level security;
alter table public.inspecoes enable row level security;
alter table public.respostas_inspecao enable row level security;
alter table public.nao_conformidades enable row level security;

-- Isolamento por usuário. Cada usuário acessa apenas seus registros.
create policy "equipamentos_selecionar_proprios" on public.equipamentos
  for select to authenticated using (criado_por = (select auth.uid()));
create policy "equipamentos_inserir_proprios" on public.equipamentos
  for insert to authenticated with check (criado_por = (select auth.uid()));
create policy "equipamentos_atualizar_proprios" on public.equipamentos
  for update to authenticated using (criado_por = (select auth.uid()))
  with check (criado_por = (select auth.uid()));
create policy "equipamentos_excluir_proprios" on public.equipamentos
  for delete to authenticated using (criado_por = (select auth.uid()));

create policy "inspecoes_selecionar_proprias" on public.inspecoes
  for select to authenticated using (criado_por = (select auth.uid()));
create policy "inspecoes_inserir_proprias" on public.inspecoes
  for insert to authenticated with check (criado_por = (select auth.uid()));
create policy "inspecoes_atualizar_proprias" on public.inspecoes
  for update to authenticated using (criado_por = (select auth.uid()))
  with check (criado_por = (select auth.uid()));
create policy "inspecoes_excluir_proprias" on public.inspecoes
  for delete to authenticated using (criado_por = (select auth.uid()));

create policy "respostas_acesso_inspecoes_proprias" on public.respostas_inspecao
  for all to authenticated
  using (exists (
    select 1 from public.inspecoes i
    where i.id = inspecao_id and i.criado_por = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.inspecoes i
    where i.id = inspecao_id and i.criado_por = (select auth.uid())
  ));

create policy "nao_conformidades_acesso_inspecoes_proprias" on public.nao_conformidades
  for all to authenticated
  using (exists (
    select 1
    from public.respostas_inspecao r
    join public.inspecoes i on i.id = r.inspecao_id
    where r.id = resposta_id and i.criado_por = (select auth.uid())
  ))
  with check (exists (
    select 1
    from public.respostas_inspecao r
    join public.inspecoes i on i.id = r.inspecao_id
    where r.id = resposta_id and i.criado_por = (select auth.uid())
  ));
