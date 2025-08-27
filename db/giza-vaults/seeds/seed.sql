SET search_path TO public;

-- 1) one vault
SELECT upsert_vault('base'::text, '0xFactory'::text, '0xVaultA'::text, now(), 123456::bigint) AS vault_id \gset

-- 2) one user, link
SELECT upsert_user('0xUserWalletA'::text) AS user_id \gset
SELECT link_user_vault(:vault_id::bigint, :user_id::bigint);

-- 3) one deposit execution
SELECT upsert_execution(
  :vault_id::bigint,
  'deposit'::action_type_enum,
  'completed'::status_enum,
  'USDC'::text,
  '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'::text,
  6::int,
  100000000::numeric,
  100.00::numeric,
  NULL::text,
  'AaveV3'::text,
  0.045::numeric,
  '0xTXHASH1'::text,
  now(),
  123457::bigint
);

-- 4) a withdrawal
SELECT upsert_execution(
  :vault_id::bigint,
  'withdraw'::action_type_enum,
  'completed'::status_enum,
  'USDC'::text,
  '0xA0b8...'::text,
  6::int,
  50000000::numeric,
  50.00::numeric,
  'AaveV3'::text,
  NULL::text,
  0.0::numeric,
  '0xTXHASH2'::text,
  now(),
  123460::bigint
);
