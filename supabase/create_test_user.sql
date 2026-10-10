-- Solicita cadastro de um usuário de teste pelo endpoint público de signup.
-- Execute uma única vez no SQL Editor do projeto Supabase.
-- Antes de executar, substitua EMAIL_DA_CONTA e SENHA_FORTE pelos dados desejados.
-- Se a confirmação de e-mail estiver ativa, confirme a conta pelo link enviado
-- antes de entrar no sistema. Este fluxo respeita a configuração de Auth do projeto.

create extension if not exists pg_net with schema extensions;

select net.http_post(
  url := 'https://asbeokorqvjgwyqkvwxr.supabase.co/auth/v1/signup',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'apikey', 'sb_publishable_EA7Kn6T0TjR6sH9muN5l4Q_KVrdpul8'
  ),
  body := jsonb_build_object(
    'email', 'EMAIL_DA_CONTA',
    'password', 'SENHA_FORTE',
    'data', jsonb_build_object('nome', 'Usuário de teste')
  ),
  timeout_milliseconds := 10000
) as request_id;

-- pg_net envia a chamada de forma assíncrona. Depois de alguns segundos,
-- consulte a resposta substituindo 1 pelo request_id retornado acima:
-- select id, status_code, content
-- from net._http_response
-- where id = 1;
-- HTTP 200 indica que o pedido de cadastro foi aceito. Se a confirmação de
-- e-mail estiver ativa, a conta ainda precisará ser confirmada para entrar.
