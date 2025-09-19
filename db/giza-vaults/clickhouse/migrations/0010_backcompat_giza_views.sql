/* Back-compat: alias to generic agents view; avoid renameat2 by using DROP + CREATE */
CREATE DATABASE IF NOT EXISTS giza;

DROP VIEW IF EXISTS giza.v_agent_tx_history;

CREATE VIEW giza.v_agent_tx_history AS
SELECT * FROM agents.v_tx_history;
