DO $$ BEGIN CREATE ROLE etl_writer LOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE api_reader LOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT USAGE ON SCHEMA public TO etl_writer, api_reader;
GRANT SELECT, INSERT, UPDATE ON vaults, users, user_vaults, executions TO etl_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO etl_writer;
GRANT SELECT ON v_vaults_from_factory, v_vault_user_associations, v_execution_history, v_agent_tx_history TO api_reader;
