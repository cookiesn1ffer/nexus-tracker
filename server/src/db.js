const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database mode detection
const usePg = !!process.env.DATABASE_URL;
let pgPool = null;
let sqliteDb = null;

// Initialize PostgreSQL
function initPg() {
  const { Pool } = require('pg');
  pgPool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL.includes('localhost') ? false : { rejectUnauthorized: false }
  });
}

// Initialize SQLite
function initSqlite() {
  const dbPath = path.join(__dirname, '../nexus.db');
  sqliteDb = new sqlite3.Database(dbPath);
}

if (usePg) {
  initPg();
} else {
  initSqlite();
}

// Convert ? placeholders to $1, $2, ... for PostgreSQL
function pgify(sql) {
  let i = 1;
  return sql.replace(/\?/g, () => `$${i++}`);
}

// Normalize errors for cross-DB compatibility
function wrapError(err) {
  if (!err) return err;
  // PostgreSQL unique violation
  if (err.code === '23505') {
    err.message = 'UNIQUE constraint failed';
  }
  return err;
}

const query = async (sql, params = []) => {
  if (usePg) {
    try {
      const result = await pgPool.query(pgify(sql), params);
      return result.rows;
    } catch (err) {
      throw wrapError(err);
    }
  }
  return new Promise((resolve, reject) => {
    sqliteDb.all(sql, params, (err, rows) => {
      if (err) reject(wrapError(err));
      else resolve(rows);
    });
  });
};

const get = async (sql, params = []) => {
  if (usePg) {
    try {
      const result = await pgPool.query(pgify(sql), params);
      return result.rows[0];
    } catch (err) {
      throw wrapError(err);
    }
  }
  return new Promise((resolve, reject) => {
    sqliteDb.get(sql, params, (err, row) => {
      if (err) reject(wrapError(err));
      else resolve(row);
    });
  });
};

const run = async (sql, params = []) => {
  if (usePg) {
    let pgSql = pgify(sql);
    // For INSERT without RETURNING, add it
    if (/^\s*INSERT\s+INTO\s+/i.test(pgSql) && !/RETURNING\s+/i.test(pgSql)) {
      pgSql += ' RETURNING id';
    }
    try {
      const result = await pgPool.query(pgSql, params);
      const id = result.rows[0]?.id;
      return { id, changes: result.rowCount };
    } catch (err) {
      throw wrapError(err);
    }
  }
  return new Promise((resolve, reject) => {
    sqliteDb.run(sql, params, function(err) {
      if (err) reject(wrapError(err));
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
};

// PostgreSQL schema
const pgSchema = `
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE,
    password_hash TEXT,
    is_admin INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS rules (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    frequency TEXT CHECK(frequency IN ('daily', 'weekly', 'one-time')) NOT NULL,
    difficulty TEXT CHECK(difficulty IN ('easy', 'medium', 'hard')) NOT NULL,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS checklist_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    rule_id INTEGER NOT NULL REFERENCES rules(id),
    completed_date TEXT NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, rule_id, completed_date)
  );

  CREATE TABLE IF NOT EXISTS writeups (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS user_xp (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    total_xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1
  );

  CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    badge_id TEXT NOT NULL,
    badge_name TEXT NOT NULL,
    badge_icon TEXT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS reactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    target_type TEXT NOT NULL,
    target_id INTEGER NOT NULL,
    emoji TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

const initDb = async () => {
  if (usePg) {
    try {
      await pgPool.query(pgSchema);
      console.log("PostgreSQL tables initialized successfully.");
    } catch (err) {
      console.error("PostgreSQL init error:", err.message);
      throw err;
    }
    return;
  }

  // SQLite
  await run('PRAGMA journal_mode = WAL');
  await run('PRAGMA foreign_keys = ON');

  await run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password_hash TEXT,
      is_admin INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS rules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      frequency TEXT CHECK(frequency IN ('daily', 'weekly', 'one-time')) NOT NULL,
      difficulty TEXT CHECK(difficulty IN ('easy', 'medium', 'hard')) NOT NULL,
      created_by INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(created_by) REFERENCES users(id)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS checklist_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      rule_id INTEGER NOT NULL,
      completed_date TEXT NOT NULL,
      completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id),
      FOREIGN KEY(rule_id) REFERENCES rules(id),
      UNIQUE(user_id, rule_id, completed_date)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS writeups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      tags TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS user_xp (
      user_id INTEGER PRIMARY KEY,
      total_xp INTEGER DEFAULT 0,
      level INTEGER DEFAULT 1,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS achievements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      badge_id TEXT NOT NULL,
      badge_name TEXT NOT NULL,
      badge_icon TEXT NOT NULL,
      unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS reactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      target_type TEXT NOT NULL,
      target_id INTEGER NOT NULL,
      emoji TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);

  console.log("SQLite tables initialized successfully.");
};

module.exports = {
  db: usePg ? pgPool : sqliteDb,
  query,
  run,
  get,
  initDb
};
