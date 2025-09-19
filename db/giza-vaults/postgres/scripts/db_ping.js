import pg from "pg";

const pool = new pg.Pool({
  host: "127.0.0.1",   // ← avoids IPv6 (::1) resolution weirdness on Windows
  port: 5433,          // you mapped 5433->5432 in docker compose
  user: "giza",        // start with the superuser you know works
  password: "supersecret",
  database: "giza_db",
  ssl: false,
  keepAlive: true,
  connectionTimeoutMillis: 8000,
});

try {
  const { rows } = await pool.query("select current_database() as db, current_user as usr");
  console.log(rows[0]);
} finally {
  await pool.end();
}