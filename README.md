# Checklist de inspeção de frota

## Configuração do Supabase

1. Execute [`supabase/schema.sql`](supabase/schema.sql) no SQL Editor do projeto Supabase.
   Se já aplicou o esquema anterior, execute também [`supabase/add_detalhes_respostas.sql`](supabase/add_detalhes_respostas.sql) para adicionar o campo JSON das medições.
2. Em **Project Settings → API**, copie a Project URL e a chave publicável (`anon`). Configure esses valores no painel **Conexão com Supabase** da página. A chave secreta `service_role` não deve ser usada no navegador.
3. Crie ou convide usuários em **Authentication → Users**. A página entra com e-mail e senha de um usuário autenticado; o esquema aplica RLS para limitar os registros ao usuário conectado.
4. Sirva `index.html` por um servidor web e mantenha acesso à CDN usada pelo cliente Supabase.

A página salva rascunhos localmente. Ao concluir uma inspeção, grava o registro em `inspecoes`, cada item e suas medições em `respostas_inspecao` e os detalhes das respostas NC em `nao_conformidades`. O histórico consulta a tabela `inspecoes` e seus registros relacionados. Os cadastros de `equipamentos` podem ser usados futuramente; o formulário atual mantém equipamento/modelo e patrimônio diretamente na inspeção, conforme os campos disponíveis no esquema.
