# Nexus Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a beautifully sleek, modern, dark-mode full-stack Accountability Tracker web application that bundles Express (backend with SQLite) and React (Vite/TS/Tailwind frontend) as a single deployable app. This will allow long-distance friends to check off ground rules, log progress writeups, and compare statistics.

**Architecture:** A unified monorepo containing a modern React/Vite/TS SPA frontend (`/client`) and an Express/Node/SQLite backend (`/server`). The backend serves the built React assets in production, allowing a simple, zero-configuration single-port deploy.

**Tech Stack:** Node.js, Express.js, SQLite (via `better-sqlite3` or `sqlite3`), jsonwebtoken, bcryptjs, React, Vite, TypeScript, Tailwind CSS, Lucide Icons, Recharts.

---

## File Structure Map
* `/` (Root directory, scripts for development and building)
  * `package.json` (Root dependencies for concurrently running client and server, and building)
* `/server` (Express Backend)
  * `package.json` (Server-specific dependencies)
  * `src/`
    * `index.js` (Express main entry point, API router, serving frontend)
    * `db.js` (SQLite initialization & schema creation)
    * `middleware/auth.js` (JWT authentication verify middleware)
    * `routes/auth.js` (User registration, login, token validation)
    * `routes/rules.js` (Shared ground rules CRUD)
    * `routes/checklists.js` (Individual checklist logs by date)
    * `routes/writeups.js` (Shared progress logs / markdown writeups)
    * `routes/stats.js` (Calculations for streaks, completion charts, and activity feed)
* `/client` (React Frontend)
  * `package.json` (Vite, React, Tailwind, Lucide, Recharts dependencies)
  * `tailwind.config.js` (Custom colors, animations, glassmorphic styles)
  * `vite.config.ts` (Build config, proxy for API requests in dev mode)
  * `src/`
    * `main.tsx`
    * `index.css` (Tailwind imports and general animations)
    * `App.tsx` (Main router and theme layout)
    * `api.ts` (Axios / fetch wrapper for server communication)
    * `context/AuthContext.tsx` (Authentication & session state)
    * `components/` (Sleek UI layouts, Dashboard widgets, visual progress rings)
      * `Layout.tsx` (Sidebar/bottom nav responsive layout)
      * `ActivityFeed.tsx` (Chronological timeline of checked items and note postings)
      * `StreakWidget.tsx` (Daily count and streak comparison flame indicator)
      * `ProgressRing.tsx` (Modern SVG visual loader of checked rules)
      * `RuleModal.tsx` (Elegant modal for rule creation)
      * `Heatmap.tsx` (GitHub-style 53-week completion box grid for both users)
    * `views/` (Main application screens)
      * `Login.tsx` (Glassmorphic login and signup page)
      * `Dashboard.tsx` (Daily checklist, streak indicator, activity feed, quick note)
      * `RulesManager.tsx` (Manage habits, frequencies, and milestones)
      * `WriteupsBoard.tsx` (Rich text/Markdown writeups with tags and user badges)
      * `Analytics.tsx` (Comparative statistics charts, streaks, and engagement details)

---

## Tasks & Steps

### Task 1: Root & Server Scaffolding
**Files:**
* Create: `/package.json`
* Create: `/server/package.json`
* Create: `/server/src/index.js`

- [ ] **Step 1: Create Root Package Config**
Set up the root workspace structure to easily start both projects concurrently.
Write `/package.json`:
```json
{
  "name": "nexus-tracker",
  "version": "1.0.0",
  "description": "Sleek accountability tracker",
  "main": "server/src/index.js",
  "scripts": {
    "install-all": "npm install && npm install --prefix server && npm install --prefix client",
    "dev": "concurrently \"npm run dev --prefix client\" \"node server/src/index.js\"",
    "build": "npm run build --prefix client && node -e \"const fs=require('fs'); if(fs.existsSync('server/public')) fs.rmSync('server/public', {recursive:true}); fs.renameSync('client/dist', 'server/public')\"",
    "start": "node server/src/index.js"
  },
  "dependencies": {
    "concurrently": "^8.2.2"
  }
}
```

- [ ] **Step 2: Create Server Package Config**
Write `/server/package.json`:
```json
{
  "name": "nexus-tracker-server",
  "version": "1.0.0",
  "main": "src/index.js",
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "sqlite3": "^5.1.7"
  }
}
```

- [ ] **Step 3: Create Server Entry Point Boilerplate**
Write `/server/src/index.js`:
```javascript
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Serving built frontend assets if they exist
app.use(express.static(path.join(__dirname, '../public')));

// Basic test route
app.get('/api/test', (req, res) => {
  res.json({ message: "Backend is operational!" });
});

// Wildcard to serve React app
app.get('*', (req, res) => {
  if (require('fs').existsSync(path.join(__dirname, '../public/index.html'))) {
    res.sendFile(path.join(__dirname, '../public/index.html'));
  } else {
    res.status(200).send("Nexus API is running! Frontend is not compiled yet.");
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
});
```

---

### Task 2: Database Initialization & SQLite Models
**Files:**
* Create: `/server/src/db.js`

- [ ] **Step 1: Write SQLite Schema Creation script**
We will use standard `sqlite3` driver and wrap it inside Promises for modern async/await execution.
Write `/server/src/db.js`:
```javascript
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const dbPath = path.join(__dirname, '../nexus.db');
const db = new sqlite3.Database(dbPath);

const query = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

const run = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
};

const get = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const initDb = async () => {
  await run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password_hash TEXT,
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

  console.log("SQLite tables initialized successfully.");
};

module.exports = {
  db,
  query,
  run,
  get,
  initDb
};
```

---

### Task 3: Backend Authentication Middleware & Auth API
**Files:**
* Create: `/server/src/middleware/auth.js`
* Create: `/server/src/routes/auth.js`
* Modify: `/server/src/index.js` to initialize DB and hook Auth routes

- [ ] **Step 1: Write Authentication Middleware**
Write `/server/src/middleware/auth.js`:
```javascript
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'nexus_super_secret_key_123';

module.exports = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: "Access denied. No token provided." });

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (ex) {
    res.status(400).json({ error: "Invalid token." });
  }
};
```

- [ ] **Step 2: Write Auth Routes (Register, Login, Me)**
Write `/server/src/routes/auth.js`:
```javascript
const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { run, get } = require('../db');
const authMiddleware = require('../middleware/auth');

const JWT_SECRET = process.env.JWT_SECRET || 'nexus_super_secret_key_123';

router.post('/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: "Please provide username and password" });

  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await run(
      'INSERT INTO users (username, password_hash) VALUES (?, ?)',
      [username.trim().toLowerCase(), hash]
    );
    const token = jwt.sign({ id: result.id, username: username.toLowerCase() }, JWT_SECRET, { expiresIn: '30d' });
    res.status(201).json({ token, user: { id: result.id, username } });
  } catch (err) {
    if (err.message.includes('UNIQUE')) {
      return res.status(400).json({ error: "Username already taken." });
    }
    res.status(500).json({ error: err.message });
  }
});

router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: "Please provide username and password" });

  try {
    const user = await get('SELECT * FROM users WHERE username = ?', [username.trim().toLowerCase()]);
    if (!user) return res.status(400).json({ error: "Invalid username or password" });

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) return res.status(400).json({ error: "Invalid username or password" });

    const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: { id: user.id, username: user.username } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await get('SELECT id, username, created_at FROM users WHERE id = ?', [req.user.id]);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 3: Update Main Index with DB & Auth Router**
Modify `/server/src/index.js` to initialize database and register auth routers. Use `edit` or `write` to set up server router hooks:
```javascript
const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDb } = require('./db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Initialize DB
initDb().catch(err => console.error("DB Initialization error:", err));

// Routes
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

// Serving built frontend assets if they exist
app.use(express.static(path.join(__dirname, '../public')));

// Basic test route
app.get('/api/test', (req, res) => {
  res.json({ message: "Backend is operational!" });
});

// Wildcard to serve React app
app.get('*', (req, res) => {
  if (require('fs').existsSync(path.join(__dirname, '../public/index.html'))) {
    res.sendFile(path.join(__dirname, '../public/index.html'));
  } else {
    res.status(200).send("Nexus API is running! Frontend is not compiled yet.");
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
});
```

---

### Task 4: API for Rules, Checklists & Writeups
**Files:**
* Create: `/server/src/routes/rules.js`
* Create: `/server/src/routes/checklists.js`
* Create: `/server/src/routes/writeups.js`
* Modify: `/server/src/index.js` to hook these routers

- [ ] **Step 1: Write Rules API**
Write `/server/src/routes/rules.js`:
```javascript
const express = require('express');
const router = express.Router();
const { run, query } = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const rules = await query('SELECT rules.*, users.username as creator FROM rules LEFT JOIN users ON rules.created_by = users.id ORDER BY rules.created_at DESC');
    res.json(rules);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const { title, description, frequency, difficulty } = req.body;
  if (!title || !frequency || !difficulty) {
    return res.status(400).json({ error: "Title, frequency and difficulty are required" });
  }

  try {
    const result = await run(
      'INSERT INTO rules (title, description, frequency, difficulty, created_by) VALUES (?, ?, ?, ?, ?)',
      [title, description || '', frequency, difficulty, req.user.id]
    );
    res.status(201).json({ id: result.id, title, description, frequency, difficulty, created_by: req.user.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    // Delete logs associated with rule first to avoid cascade issues
    await run('DELETE FROM checklist_logs WHERE rule_id = ?', [req.params.id]);
    const result = await run('DELETE FROM rules WHERE id = ?', [req.params.id]);
    res.json({ message: "Rule deleted successfully", result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 2: Write Checklist Log Toggle API**
Write `/server/src/routes/checklists.js`:
```javascript
const express = require('express');
const router = express.Router();
const { run, query, get } = require('../db');
const authMiddleware = require('../middleware/auth');

// Get checklist completions for a particular date (YYYY-MM-DD) for both users
router.get('/', authMiddleware, async (req, res) => {
  const { date } = req.query; // Expects YYYY-MM-DD
  if (!date) return res.status(400).json({ error: "Date parameter is required" });

  try {
    const completions = await query(
      `SELECT checklist_logs.*, users.username 
       FROM checklist_logs 
       JOIN users ON checklist_logs.user_id = users.id 
       WHERE completed_date = ?`,
      [date]
    );
    res.json(completions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Toggle completion of a rule
router.post('/toggle', authMiddleware, async (req, res) => {
  const { ruleId, date } = req.body; // ruleId, YYYY-MM-DD
  if (!ruleId || !date) return res.status(400).json({ error: "ruleId and date are required" });

  try {
    const userId = req.user.id;
    // Check if completion already exists
    const existing = await get(
      'SELECT id FROM checklist_logs WHERE user_id = ? AND rule_id = ? AND completed_date = ?',
      [userId, ruleId, date]
    );

    if (existing) {
      // If checked, uncheck (delete completion log)
      await run('DELETE FROM checklist_logs WHERE id = ?', [existing.id]);
      res.json({ checked: false, ruleId });
    } else {
      // If unchecked, check (insert completion log)
      await run(
        'INSERT INTO checklist_logs (user_id, rule_id, completed_date) VALUES (?, ?, ?)',
        [userId, ruleId, date]
      );
      res.json({ checked: true, ruleId });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 3: Write Writeups Notes API**
Write `/server/src/routes/writeups.js`:
```javascript
const express = require('express');
const router = express.Router();
const { run, query } = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const writeups = await query(
      `SELECT writeups.*, users.username 
       FROM writeups 
       JOIN users ON writeups.user_id = users.id 
       ORDER BY writeups.created_at DESC`
    );
    res.json(writeups);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const { title, content, tags } = req.body;
  if (!title || !content) return res.status(400).json({ error: "Title and content are required" });

  try {
    const result = await run(
      'INSERT INTO writeups (user_id, title, content, tags) VALUES (?, ?, ?, ?)',
      [req.user.id, title, content, tags || '']
    );
    res.status(201).json({
      id: result.id,
      user_id: req.user.id,
      username: req.user.username,
      title,
      content,
      tags,
      created_at: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const writeup = await get('SELECT user_id FROM writeups WHERE id = ?', [req.params.id]);
    if (!writeup) return res.status(404).json({ error: "Writeup not found" });

    // Protect delete so only author can delete
    if (writeup.user_id !== req.user.id) {
      return res.status(403).json({ error: "You can only delete your own writeups" });
    }

    await run('DELETE FROM writeups WHERE id = ?', [req.params.id]);
    res.json({ message: "Writeup deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 4: Hook routers in `/server/src/index.js`**
Modify `/server/src/index.js` to register the new API endpoints. Use `edit`:
```javascript
// ... under const authRoutes = require('./routes/auth');
const rulesRoutes = require('./routes/rules');
const checklistRoutes = require('./routes/checklists');
const writeupsRoutes = require('./routes/writeups');

app.use('/api/auth', authRoutes);
app.use('/api/rules', rulesRoutes);
app.use('/api/checklists', checklistRoutes);
app.use('/api/writeups', writeupsRoutes);
```

---

### Task 5: Backend Analytics, Streaks & Unified Activity Feed
**Files:**
* Create: `/server/src/routes/stats.js`
* Modify: `/server/src/index.js` to register stats router

- [ ] **Step 1: Write Stats API (Calculates Streaks, Feed, and Heatmap Grid Data)**
We need to calculate current/max streaks for all users. A streak represents successive calendar days with at least one completed checklist target.
Write `/server/src/routes/stats.js`:
```javascript
const express = require('express');
const router = express.Router();
const { query } = require('../db');
const authMiddleware = require('../middleware/auth');

function calculateStreaks(dates) {
  if (!dates || dates.length === 0) return { currentStreak: 0, maxStreak: 0 };

  // Unique sorted dates
  const uniqueDates = [...new Set(dates)].map(d => new Date(d)).sort((a, b) => b - a); // Descending (latest first)

  let currentStreak = 0;
  let maxStreak = 0;
  let tempStreak = 0;

  const today = new Date();
  today.setHours(0,0,0,0);
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  // Check if latest date completed is today or yesterday to continue current streak
  const latestDate = uniqueDates[0];
  latestDate.setHours(0,0,0,0);

  const maintainsCurrent = (latestDate.getTime() === today.getTime() || latestDate.getTime() === yesterday.getTime());

  // Calculate descending to find consecutive days
  let prevDate = null;
  let count = 0;

  // Let's sort ascending for max streak calculations
  const ascDates = [...new Set(dates)].map(d => new Date(d)).sort((a, b) => a - b);
  let maxCount = 0;
  let currCount = 0;
  let lastDate = null;

  for (let i = 0; i < ascDates.length; i++) {
    const d = ascDates[i];
    d.setHours(0,0,0,0);

    if (lastDate === null) {
      currCount = 1;
    } else {
      const diffTime = Math.abs(d - lastDate);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays === 1) {
        currCount++;
      } else if (diffDays > 1) {
        currCount = 1;
      }
    }
    if (currCount > maxCount) maxCount = currCount;
    lastDate = d;
  }

  // Current Streak Calculation (Descending)
  if (maintainsCurrent) {
    let currentLast = today;
    // Check consecutive days backwards
    const formattedUnique = [...new Set(dates)].sort().reverse(); // Descending strings
    const todayStr = today.toISOString().split('T')[0];
    const yesterdayStr = yesterday.toISOString().split('T')[0];

    let checkDateStr = formattedUnique.includes(todayStr) ? todayStr : yesterdayStr;
    let expected = new Date(checkDateStr);
    let consecutive = 0;

    while (formattedUnique.includes(checkDateStr)) {
      consecutive++;
      expected.setDate(expected.getDate() - 1);
      checkDateStr = expected.toISOString().split('T')[0];
    }
    currentStreak = consecutive;
  } else {
    currentStreak = 0;
  }

  return {
    currentStreak,
    maxStreak: maxCount
  };
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    // 1. Get all users
    const users = await query('SELECT id, username FROM users');

    // 2. Get history activity logs
    const completions = await query(`
      SELECT 'checklist' as type, checklist_logs.id, checklist_logs.user_id, users.username, 
             rules.title as item_title, checklist_logs.completed_date as date, checklist_logs.completed_at as timestamp 
      FROM checklist_logs 
      JOIN users ON checklist_logs.user_id = users.id
      JOIN rules ON checklist_logs.rule_id = rules.id
    `);

    const rawWriteups = await query(`
      SELECT 'writeup' as type, writeups.id, writeups.user_id, users.username, 
             writeups.title as item_title, writeups.created_at as timestamp 
      FROM writeups 
      JOIN users ON writeups.user_id = users.id
    `);

    // Merge feed
    const feed = [...completions, ...rawWriteups]
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
      .slice(0, 50); // Last 50 actions

    // 3. User analytical stats (Streaks, Heatmap, Total completions)
    const userStats = {};
    for (let user of users) {
      // Get completed dates
      const logs = await query('SELECT completed_date FROM checklist_logs WHERE user_id = ?', [user.id]);
      const dates = logs.map(l => l.completed_date);

      const streaks = calculateStreaks(dates);
      
      userStats[user.username] = {
        userId: user.id,
        completedCount: dates.length,
        currentStreak: streaks.currentStreak,
        maxStreak: streaks.maxStreak,
        completedDates: dates // Sent for heatmap rendering
      };
    }

    res.json({
      feed,
      userStats
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 2: Register Stats Routes**
Modify `/server/src/index.js` to register `/api/stats` endpoint. Use `edit`.
```javascript
// ... under app.use('/api/writeups', writeupsRoutes);
const statsRoutes = require('./routes/stats');
app.use('/api/stats', statsRoutes);
```

---

### Task 6: Frontend Project Scaffolding (Vite + TS + Tailwind)
**Files:**
* Create: `/client/package.json`
* Create: `/client/tsconfig.json`
* Create: `/client/vite.config.ts`
* Create: `/client/tailwind.config.js`
* Create: `/client/src/index.css`
* Create: `/client/src/main.tsx`

- [ ] **Step 1: Write Client Package.json**
Write `/client/package.json`:
```json
{
  "name": "nexus-tracker-client",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "lucide-react": "^0.378.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "recharts": "^2.12.7"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.0",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.3",
    "typescript": "^5.2.2",
    "vite": "^5.2.11"
  }
}
```

- [ ] **Step 2: Write Vite Configuration with Dev Proxy**
Configure Vite to proxy API requests in development to the local Express server on port 5000.
Write `/client/vite.config.ts`:
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
});
```

- [ ] **Step 3: Write Tailwind & CSS Styling**
We need smooth glassmorphism utility classes and dark background defaults.
Write `/client/tailwind.config.js`:
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          bg: '#0b0f19',
          card: '#161e2e',
          border: '#243242'
        },
        brand: {
          primary: '#6366f1', // Indigo
          success: '#10b981', // Emerald
          warning: '#f59e0b', // Amber
          danger: '#f43f5e'   // Rose
        }
      },
      boxShadow: {
        glow: '0 0 15px rgba(99, 102, 241, 0.35)',
        'glow-success': '0 0 15px rgba(16, 185, 129, 0.35)',
      }
    },
  },
  plugins: [],
}
```

Write `/client/src/index.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  background-color: #0b0f19;
  color: #f3f4f6;
  font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  margin: 0;
  overflow-x: hidden;
}

/* Custom Glassmorphism styles */
.glass-panel {
  background: rgba(22, 30, 46, 0.7);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.glass-input {
  background: rgba(11, 15, 25, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #fff;
  transition: all 0.2s ease;
}

.glass-input:focus {
  border-color: #6366f1;
  box-shadow: 0 0 10px rgba(99, 102, 241, 0.25);
  outline: none;
}

/* Hide scrollbar */
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
```

- [ ] **Step 4: Create Main tsconfig.json & index.html**
Write `/client/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["DOM", "DOM.Iterable", "ES2020"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
```

Write `/client/index.html`:
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Nexus Accountability Tracker</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

Write `/client/src/main.tsx`:
```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

---

### Task 7: Frontend Auth Context & API Client
**Files:**
* Create: `/client/src/api.ts`
* Create: `/client/src/context/AuthContext.tsx`

- [ ] **Step 1: Write Custom API Caller Wrapper**
Make a clean api routing framework that manages the browser JWT.
Write `/client/src/api.ts`:
```typescript
const BASE_URL = ''; // Relative paths to use proxy in dev and same-host routing in prod

async function request(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('nexus_token');
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
  };

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      ...headers,
      ...options.headers
    }
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error || 'Something went wrong');
  }
  return data;
}

export const api = {
  get: (endpoint: string) => request(endpoint, { method: 'GET' }),
  post: (endpoint: string, body: any) => request(endpoint, {
    method: 'POST',
    body: JSON.stringify(body)
  }),
  delete: (endpoint: string) => request(endpoint, { method: 'DELETE' })
};
```

- [ ] **Step 2: Write React Authentication State Provider Context**
Write `/client/src/context/AuthContext.tsx`:
```typescript
import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../api';

interface User {
  id: number;
  username: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadUser() {
      const token = localStorage.getItem('nexus_token');
      if (token) {
        try {
          const userData = await api.get('/api/auth/me');
          setUser(userData);
        } catch (err) {
          console.error("Failed to fetch user profiles", err);
          logout();
        }
      }
      setLoading(false);
    }
    loadUser();
  }, []);

  const login = async (username: string, password: string) => {
    const res = await api.post('/api/auth/login', { username, password });
    localStorage.setItem('nexus_token', res.token);
    setUser(res.user);
  };

  const register = async (username: string, password: string) => {
    const res = await api.post('/api/auth/register', { username, password });
    localStorage.setItem('nexus_token', res.token);
    setUser(res.user);
  };

  const logout = () => {
    localStorage.removeItem('nexus_token');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used inside AuthProvider');
  return context;
}
```

---

### Task 8: Login Interface & Navigation Layout
**Files:**
* Create: `/client/src/views/Login.tsx`
* Create: `/client/src/components/Layout.tsx`
* Create: `/client/src/components/ProgressRing.tsx`

- [ ] **Step 1: Write Custom Login and Signup View Screen**
Write `/client/src/views/Login.tsx`:
```typescript
import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Sparkles, Shield, User, Lock, ArrowRight } from 'lucide-react';

export default function Login() {
  const { login, register } = useAuth();
  const [isLogin, setIsLogin] = useState(true);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (isLogin) {
        await login(username, password);
      } else {
        await register(username, password);
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-dark-bg">
      {/* Decorative Blur Backgrounds */}
      <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] rounded-full bg-indigo-900/20 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] rounded-full bg-emerald-900/20 blur-[120px] pointer-events-none" />

      <div className="w-full max-w-md glass-panel p-8 rounded-2xl shadow-glow relative z-10 border border-white/10">
        <div className="text-center mb-8">
          <div className="inline-flex p-3 rounded-xl bg-indigo-600/15 text-indigo-400 mb-3 border border-indigo-500/20 shadow-[0_0_15px_rgba(99,102,241,0.15)]">
            <Sparkles className="w-6 h-6 animate-pulse" />
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-white">NEXUS TRACKER</h1>
          <p className="text-gray-400 text-sm mt-2">Dual accountability system for remote friends</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="p-3 bg-red-500/10 border border-red-500/20 text-red-400 rounded-lg text-sm">
              {error}
            </div>
          )}

          <div>
            <label className="block text-gray-300 text-sm font-medium mb-1.5">Username</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                <User className="w-4.5 h-4.5" />
              </span>
              <input
                type="text"
                value={username}
                onChange={e => setUsername(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 rounded-lg glass-input text-sm"
                placeholder="Enter username"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-gray-300 text-sm font-medium mb-1.5">Password</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                <Lock className="w-4.5 h-4.5" />
              </span>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 rounded-lg glass-input text-sm"
                placeholder="Enter password"
                required
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2.5 rounded-lg text-sm transition-all shadow-[0_0_15px_rgba(99,102,241,0.3)] flex items-center justify-center gap-2 group cursor-pointer disabled:opacity-50"
          >
            {loading ? 'Processing...' : isLogin ? 'Sign In' : 'Create Account'}
            <ArrowRight className="w-4.5 h-4.5 group-hover:translate-x-0.5 transition-transform" />
          </button>
        </form>

        <div className="mt-6 text-center">
          <button
            onClick={() => setIsLogin(!isLogin)}
            className="text-indigo-400 hover:text-indigo-300 text-xs font-medium focus:outline-none"
          >
            {isLogin ? "New pair? Register here" : "Already registered? Login here"}
          </button>
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Write Layout Component with Mobile Navigation support**
Write `/client/src/components/Layout.tsx`:
```typescript
import React from 'react';
import { useAuth } from '../context/AuthContext';
import { Home, ClipboardList, BookOpen, BarChart3, LogOut, CheckCircle } from 'lucide-react';

interface LayoutProps {
  children: React.ReactNode;
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export default function Layout({ children, activeTab, setActiveTab }: LayoutProps) {
  const { user, logout } = useAuth();

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: Home },
    { id: 'rules', label: 'Ground Rules', icon: ClipboardList },
    { id: 'writeups', label: 'Writeups', icon: BookOpen },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 },
  ];

  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-dark-bg text-gray-100">
      {/* Sidebar - Desktop */}
      <aside className="hidden md:flex flex-col w-64 bg-dark-card border-r border-dark-border px-4 py-6 justify-between shrink-0">
        <div>
          {/* Logo */}
          <div className="flex items-center gap-3 px-3 mb-8">
            <div className="p-2 rounded-lg bg-indigo-600 text-white">
              <CheckCircle className="w-5 h-5" />
            </div>
            <div>
              <span className="font-extrabold tracking-tight text-lg text-white">NEXUS</span>
              <span className="text-indigo-400 font-bold text-xs ml-1 px-1.5 py-0.5 bg-indigo-950 rounded-md border border-indigo-800">TRACKER</span>
            </div>
          </div>

          {/* User profile capsule */}
          <div className="px-3 py-2.5 rounded-xl bg-dark-bg border border-dark-border flex items-center justify-between mb-6">
            <div className="flex flex-col">
              <span className="text-xs text-gray-400">Logged in as</span>
              <span className="text-sm font-bold text-indigo-400">@{user?.username}</span>
            </div>
          </div>

          {/* Navigation links */}
          <nav className="space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all cursor-pointer ${
                    isActive
                      ? 'bg-indigo-600/15 text-indigo-400 border border-indigo-500/20'
                      : 'text-gray-400 hover:text-white hover:bg-white/5'
                  }`}
                >
                  <Icon className="w-4.5 h-4.5" />
                  {item.label}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Logout */}
        <button
          onClick={logout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-rose-400 hover:bg-rose-500/10 transition-all cursor-pointer"
        >
          <LogOut className="w-4.5 h-4.5" />
          Logout
        </button>
      </aside>

      {/* Top Header & Navigation - Mobile */}
      <header className="md:hidden bg-dark-card border-b border-dark-border px-4 py-3.5 flex items-center justify-between sticky top-0 z-40">
        <div className="flex items-center gap-2">
          <CheckCircle className="w-5 h-5 text-indigo-500" />
          <span className="font-extrabold tracking-tight text-white">NEXUS</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-xs text-indigo-400 bg-indigo-950/40 px-2 py-1 rounded border border-indigo-900">@{user?.username}</span>
          <button onClick={logout} className="p-1.5 text-rose-400 hover:bg-rose-500/10 rounded-lg">
            <LogOut className="w-4.5 h-4.5" />
          </button>
        </div>
      </header>

      {/* Content pane */}
      <main className="flex-1 overflow-y-auto px-4 md:px-8 py-6 md:py-8 pb-24 md:pb-8 max-w-7xl mx-auto w-full">
        {children}
      </main>

      {/* Navigation - Bottom bar Mobile */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-dark-card/95 border-t border-dark-border py-2 px-4 flex justify-around items-center z-40 backdrop-blur-lg shadow-2xl">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`flex flex-col items-center gap-0.5 py-1 text-[10px] font-medium transition-all ${
                isActive ? 'text-indigo-400 scale-105' : 'text-gray-400'
              }`}
            >
              <Icon className="w-5 h-5" />
              {item.label}
            </button>
          );
        })}
      </nav>
    </div>
  );
}
```

- [ ] **Step 3: Write Progress SVG Ring Component**
Write `/client/src/components/ProgressRing.tsx`:
```typescript
import React from 'react';

interface ProgressRingProps {
  size?: number;
  strokeWidth?: number;
  progress: number; // 0 to 100
  colorClass?: string;
}

export default function ProgressRing({ size = 120, strokeWidth = 10, progress, colorClass = 'stroke-indigo-500' }: ProgressRingProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const strokeDashoffset = circumference - (Math.min(Math.max(progress, 0), 100) / 100) * circumference;

  return (
    <div className="relative flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        {/* Track circle */}
        <circle
          className="stroke-dark-border"
          fill="transparent"
          strokeWidth={strokeWidth}
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
        {/* Animated Progress circle */}
        <circle
          className={`${colorClass} transition-all duration-500 ease-out`}
          fill="transparent"
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
      </svg>
      {/* Percentage Center Text */}
      <div className="absolute flex flex-col items-center">
        <span className="text-xl font-extrabold text-white">{Math.round(progress)}%</span>
        <span className="text-[9px] text-gray-400 uppercase tracking-widest font-semibold">Done</span>
      </div>
    </div>
  );
}
```

---

### Task 9: Rules & Dashboard Checklist Views
**Files:**
* Create: `/client/src/views/RulesManager.tsx`
* Create: `/client/src/views/Dashboard.tsx`

- [ ] **Step 1: Write Ground Rules Configurator screen**
Write `/client/src/views/RulesManager.tsx`:
```typescript
import React, { useState, useEffect } from 'react';
import { api } from '../api';
import { Plus, Trash2, Calendar, ShieldAlert, Award } from 'lucide-react';

interface Rule {
  id: number;
  title: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'one-time';
  difficulty: 'easy' | 'medium' | 'hard';
  creator: string;
}

export default function RulesManager() {
  const [rules, setRules] = useState<Rule[]>([]);
  const [loading, setLoading] = useState(true);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [frequency, setFrequency] = useState<'daily' | 'weekly' | 'one-time'>('daily');
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('medium');
  const [error, setError] = useState('');

  const fetchRules = async () => {
    try {
      const data = await api.get('/api/rules');
      setRules(data);
    } catch (err: any) {
      setError('Failed to fetch rules');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRules();
  }, []);

  const handleAddRule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title) return;
    setError('');
    try {
      await api.post('/api/rules', { title, description, frequency, difficulty });
      setTitle('');
      setDescription('');
      setFrequency('daily');
      setDifficulty('medium');
      fetchRules();
    } catch (err: any) {
      setError(err.message || 'Failed to add rule');
    }
  };

  const handleDeleteRule = async (id: number) => {
    if (!confirm('Are you sure you want to delete this rule? This deletes all history completions.')) return;
    try {
      await api.delete(`/api/rules/${id}`);
      fetchRules();
    } catch (err) {
      setError('Failed to delete rule');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold tracking-tight">Ground Rules</h2>
        <p className="text-gray-400 text-sm mt-1">Set targets, habits, and milestone challenges for accountability.</p>
      </div>

      {error && (
        <div className="p-3 bg-rose-500/10 border border-rose-500/20 text-rose-400 rounded-lg text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Creation Box */}
        <div className="glass-panel p-6 rounded-2xl h-fit border border-white/5 space-y-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <Plus className="w-5 h-5 text-indigo-400" />
            Add New Rule
          </h3>
          <form onSubmit={handleAddRule} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Rule Title</label>
              <input
                type="text"
                placeholder="e.g. Code for 1 hour"
                value={title}
                onChange={e => setTitle(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Description</label>
              <textarea
                placeholder="Details of the challenge..."
                value={description}
                onChange={e => setDescription(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm h-20 resize-none"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Frequency</label>
                <select
                  value={frequency}
                  onChange={e => setFrequency(e.target.value as any)}
                  className="w-full py-2 px-3 rounded-lg glass-input text-sm bg-dark-bg cursor-pointer"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="one-time">One-time</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Difficulty</label>
                <select
                  value={difficulty}
                  onChange={e => setDifficulty(e.target.value as any)}
                  className="w-full py-2 px-3 rounded-lg glass-input text-sm bg-dark-bg cursor-pointer"
                >
                  <option value="easy">Easy</option>
                  <option value="medium">Medium</option>
                  <option value="hard">Hard</option>
                </select>
              </div>
            </div>
            <button
              type="submit"
              className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2 rounded-lg text-sm transition-all shadow-[0_0_15px_rgba(99,102,241,0.2)] cursor-pointer"
            >
              Add Rule
            </button>
          </form>
        </div>

        {/* Active Rules List */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-lg font-bold text-white">Active Accountability Rules</h3>
          {loading ? (
            <div className="text-gray-400 text-sm py-12 text-center">Loading rules...</div>
          ) : rules.length === 0 ? (
            <div className="glass-panel p-8 rounded-2xl text-center border border-white/5 text-gray-400 text-sm">
              No ground rules defined. Add one above to kick off the accountability contest!
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {rules.map((rule) => (
                <div key={rule.id} className="glass-panel p-5 rounded-2xl border border-white/5 flex flex-col justify-between group hover:border-white/10 transition-all">
                  <div>
                    <div className="flex items-start justify-between">
                      <h4 className="font-bold text-white group-hover:text-indigo-400 transition-colors">{rule.title}</h4>
                      <button
                        onClick={() => handleDeleteRule(rule.id)}
                        className="p-1 text-gray-400 hover:text-rose-500 rounded transition-colors cursor-pointer"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                    <p className="text-gray-400 text-xs mt-1.5 line-clamp-2">{rule.description || "No description provided."}</p>
                  </div>
                  <div className="flex gap-2 mt-4 flex-wrap">
                    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded bg-indigo-950/50 text-indigo-400 border border-indigo-900">
                      <Calendar className="w-3 h-3" />
                      {rule.frequency}
                    </span>
                    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded border ${
                      rule.difficulty === 'easy' ? 'bg-emerald-950/50 text-emerald-400 border-emerald-900' :
                      rule.difficulty === 'medium' ? 'bg-amber-950/50 text-amber-400 border-amber-900' :
                      'bg-rose-950/50 text-rose-400 border-rose-900'
                    }`}>
                      <Award className="w-3 h-3" />
                      {rule.difficulty}
                    </span>
                    <span className="text-[10px] text-gray-500 self-center ml-auto">By @{rule.creator}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Write Main Accountability Dashboard screen (Personal Checklist & Live sync feed)**
Write `/client/src/views/Dashboard.tsx`:
```typescript
import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../api';
import ProgressRing from '../components/ProgressRing';
import { CheckSquare, Square, Flame, Plus, History, Notebook, MessageSquare, Tag } from 'lucide-react';

interface Rule {
  id: number;
  title: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'one-time';
  difficulty: 'easy' | 'medium' | 'hard';
}

interface Completion {
  id: number;
  rule_id: number;
  user_id: number;
  username: string;
  completed_date: string;
}

interface FeedItem {
  type: 'checklist' | 'writeup';
  id: number;
  user_id: number;
  username: string;
  item_title: string;
  date?: string;
  timestamp: string;
}

interface UserStat {
  userId: number;
  completedCount: number;
  currentStreak: number;
  maxStreak: number;
}

export default function Dashboard() {
  const { user } = useAuth();
  const [rules, setRules] = useState<Rule[]>([]);
  const [completions, setCompletions] = useState<Completion[]>([]);
  const [feed, setFeed] = useState<FeedItem[]>([]);
  const [userStats, setUserStats] = useState<Record<string, UserStat>>({});
  const [loading, setLoading] = useState(true);

  // Quick note states
  const [noteTitle, setNoteTitle] = useState('');
  const [noteContent, setNoteContent] = useState('');
  const [noteTags, setNoteTags] = useState('');
  const [noteSuccess, setNoteSuccess] = useState(false);

  const todayStr = new Date().toISOString().split('T')[0];

  const fetchData = async () => {
    try {
      const rulesData = await api.get('/api/rules');
      const completionsData = await api.get(`/api/checklists?date=${todayStr}`);
      const statsData = await api.get('/api/stats');
      
      setRules(rulesData);
      setCompletions(completionsData);
      setFeed(statsData.feed);
      setUserStats(statsData.userStats);
    } catch (err) {
      console.error("Dashboard failed to retrieve active sessions", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // Poll every 10 seconds for real-time like sync with their friend
    const interval = setInterval(fetchData, 10000);
    return () => clearInterval(interval);
  }, []);

  const handleToggle = async (ruleId: number) => {
    try {
      await api.post('/api/checklists/toggle', { ruleId, date: todayStr });
      fetchData();
    } catch (err) {
      console.error(err);
    }
  };

  const handleQuickNote = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!noteTitle || !noteContent) return;
    try {
      await api.post('/api/writeups', { title: noteTitle, content: noteContent, tags: noteTags });
      setNoteTitle('');
      setNoteContent('');
      setNoteTags('');
      setNoteSuccess(true);
      fetchData();
      setTimeout(() => setNoteSuccess(false), 3000);
    } catch (err) {
      console.error(err);
    }
  };

  // Compute stats for current user
  const userCompletions = completions.filter(c => c.user_id === user?.id).map(c => c.rule_id);
  const completionPercentage = rules.length > 0 ? (userCompletions.length / rules.length) * 100 : 0;

  // Find friend stats
  const friendName = Object.keys(userStats).find(name => name !== user?.username);
  const friendStreak = friendName ? userStats[friendName].currentStreak : 0;
  const myStreak = user?.username ? userStats[user.username]?.currentStreak || 0 : 0;

  return (
    <div className="space-y-6">
      {/* Welcome Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-extrabold tracking-tight">Status Hub</h2>
          <p className="text-gray-400 text-sm mt-1">Consistency check with your accountability partner.</p>
        </div>
        
        {/* Streak Flame capsules */}
        <div className="flex gap-3">
          <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-dark-card border border-dark-border shadow-[0_0_15px_rgba(239,68,68,0.05)]">
            <Flame className="w-5 h-5 text-orange-500 fill-orange-500 animate-pulse" />
            <div>
              <div className="text-[9px] uppercase tracking-wider text-gray-400 font-semibold">Your Streak</div>
              <div className="text-sm font-black text-white">{myStreak} Days</div>
            </div>
          </div>
          {friendName && (
            <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-dark-card border border-dark-border">
              <Flame className="w-5 h-5 text-zinc-500" />
              <div>
                <div className="text-[9px] uppercase tracking-wider text-gray-400 font-semibold">@{friendName}'s</div>
                <div className="text-sm font-black text-gray-300">{friendStreak} Days</div>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Checklist Widget */}
        <div className="lg:col-span-2 space-y-6">
          <div className="glass-panel p-6 rounded-2xl border border-white/5 flex flex-col md:flex-row items-center gap-6 justify-between">
            <div className="space-y-1.5 text-center md:text-left">
              <h3 className="text-lg font-black text-white">Your Targets Today</h3>
              <p className="text-gray-400 text-xs max-w-sm">Completing rules daily increments your accountability streak. Stay consistent!</p>
              <div className="text-xs text-indigo-400 font-bold bg-indigo-950/40 border border-indigo-900 rounded-md px-2 py-0.5 inline-block mt-1">
                📅 Today: {new Date().toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' })}
              </div>
            </div>
            <div className="shrink-0">
              <ProgressRing progress={completionPercentage} />
            </div>
          </div>

          {/* Actual checklists */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
            <h4 className="text-sm font-bold text-gray-300 uppercase tracking-widest">Rule Items</h4>
            {loading ? (
              <div className="text-gray-400 text-sm py-6 text-center">Loading list...</div>
            ) : rules.length === 0 ? (
              <div className="text-center py-8 text-gray-500 text-sm">
                No ground rules established yet. Go to "Ground Rules" tab to configure tasks.
              </div>
            ) : (
              <div className="space-y-2">
                {rules.map((rule) => {
                  const isCompleted = userCompletions.includes(rule.id);
                  return (
                    <button
                      key={rule.id}
                      onClick={() => handleToggle(rule.id)}
                      className={`w-full flex items-center justify-between text-left p-4 rounded-xl border transition-all cursor-pointer group ${
                        isCompleted
                          ? 'bg-emerald-950/20 border-emerald-500/20 text-gray-300'
                          : 'bg-dark-bg/60 border-white/5 hover:border-white/10 text-white'
                      }`}
                    >
                      <div className="flex items-center gap-3.5 pr-4">
                        {isCompleted ? (
                          <CheckSquare className="w-5.5 h-5.5 text-emerald-400 shrink-0" />
                        ) : (
                          <Square className="w-5.5 h-5.5 text-gray-500 shrink-0 group-hover:text-indigo-400 transition-colors" />
                        )}
                        <div>
                          <p className={`font-semibold text-sm ${isCompleted ? 'line-through text-gray-500' : ''}`}>{rule.title}</p>
                          <p className="text-[11px] text-gray-400 mt-0.5 line-clamp-1">{rule.description || 'No description'}</p>
                        </div>
                      </div>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded border uppercase shrink-0 ${
                        rule.difficulty === 'easy' ? 'bg-emerald-950/50 text-emerald-400 border-emerald-900' :
                        rule.difficulty === 'medium' ? 'bg-amber-950/50 text-amber-400 border-amber-900' :
                        'bg-rose-950/50 text-rose-400 border-rose-900'
                      }`}>
                        {rule.difficulty}
                      </span>
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Sync Feed & Quick Note Loggers */}
        <div className="space-y-6">
          {/* Quick Writeup Logger */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
            <h3 className="text-md font-bold text-white flex items-center gap-2">
              <Notebook className="w-4.5 h-4.5 text-indigo-400" />
              Quick Writeup Log
            </h3>
            {noteSuccess && (
              <div className="p-2.5 text-xs text-emerald-400 bg-emerald-950/20 border border-emerald-500/20 rounded-lg">
                Progress logged successfully to shared feed!
              </div>
            )}
            <form onSubmit={handleQuickNote} className="space-y-3">
              <input
                type="text"
                placeholder="Title: e.g. Finished DB routes"
                value={noteTitle}
                onChange={e => setNoteTitle(e.target.value)}
                className="w-full px-3 py-2 rounded-lg glass-input text-xs"
                required
              />
              <textarea
                placeholder="What progress did you make? Blocks?"
                value={noteContent}
                onChange={e => setNoteContent(e.target.value)}
                className="w-full px-3 py-2 rounded-lg glass-input text-xs h-16 resize-none"
                required
              />
              <input
                type="text"
                placeholder="Tags: success, blockers (comma-separated)"
                value={noteTags}
                onChange={e => setNoteTags(e.target.value)}
                className="w-full px-3 py-2 rounded-lg glass-input text-xs"
              />
              <button
                type="submit"
                className="w-full py-1.5 text-xs font-semibold rounded-lg bg-indigo-600 hover:bg-indigo-500 transition-colors shadow-[0_0_10px_rgba(99,102,241,0.15)] cursor-pointer text-white"
              >
                Log Writeup
              </button>
            </form>
          </div>

          {/* Activity Feed */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
            <h3 className="text-md font-bold text-white flex items-center gap-2">
              <History className="w-4.5 h-4.5 text-indigo-400" />
              Who Did What Feed
            </h3>
            <div className="space-y-4 max-h-[280px] overflow-y-auto no-scrollbar pr-1">
              {feed.length === 0 ? (
                <p className="text-xs text-gray-500 text-center py-6">No recent actions logged.</p>
              ) : (
                feed.map((item, idx) => (
                  <div key={`${item.type}-${item.id}-${idx}`} className="flex gap-3 text-xs">
                    <div className="flex flex-col items-center">
                      <div className={`p-1.5 rounded-full shrink-0 ${
                        item.type === 'checklist' ? 'bg-emerald-500/15 text-emerald-400' : 'bg-indigo-500/15 text-indigo-400'
                      }`}>
                        {item.type === 'checklist' ? (
                          <CheckSquare className="w-3.5 h-3.5" />
                        ) : (
                          <MessageSquare className="w-3.5 h-3.5" />
                        )}
                      </div>
                      {idx < feed.length - 1 && <div className="w-0.5 h-full bg-dark-border mt-1.5" />}
                    </div>
                    <div className="pb-2 flex-1">
                      <p className="text-gray-300">
                        <span className="font-bold text-indigo-400">@{item.username}</span>{' '}
                        {item.type === 'checklist' ? 'checked off' : 'posted writeup'}{' '}
                        <span className="text-white font-medium">"{item.item_title}"</span>
                      </p>
                      <span className="text-[10px] text-gray-500 block mt-1">
                        {new Date(item.timestamp).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

### Task 10: Rich Notes Writeups View
**Files:**
* Create: `/client/src/views/WriteupsBoard.tsx`

- [ ] **Step 1: Write Custom Writeups board screen (Full notes board)**
Write `/client/src/views/WriteupsBoard.tsx`:
```typescript
import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../api';
import { Plus, Trash2, Tag, Calendar, User, MessageCircle } from 'lucide-react';

interface Writeup {
  id: number;
  user_id: number;
  username: string;
  title: string;
  content: string;
  tags: string;
  created_at: string;
}

export default function WriteupsBoard() {
  const { user } = useAuth();
  const [writeups, setWriteups] = useState<Writeup[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Note input states
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [tags, setTags] = useState('');
  const [error, setError] = useState('');

  const fetchWriteups = async () => {
    try {
      const data = await api.get('/api/writeups');
      setWriteups(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWriteups();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !content) return;
    setError('');
    try {
      await api.post('/api/writeups', { title, content, tags });
      setTitle('');
      setContent('');
      setTags('');
      fetchWriteups();
    } catch (err: any) {
      setError(err.message || 'Failed to submit writeup');
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this writeup?')) return;
    try {
      await api.delete(`/api/writeups/${id}`);
      fetchWriteups();
    } catch (err) {
      setError('Failed to delete writeup');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold tracking-tight">Writeups Shared Notebook</h2>
        <p className="text-gray-400 text-sm mt-1">Log progress diaries, design briefs, snippets, and blockers.</p>
      </div>

      {error && (
        <div className="p-3 bg-rose-500/10 border border-rose-500/20 text-rose-400 rounded-lg text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Creator Panel */}
        <div className="glass-panel p-6 rounded-2xl border border-white/5 h-fit space-y-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <Plus className="w-5 h-5 text-indigo-400" />
            Add Writeup Note
          </h3>
          <form onSubmit={handleCreate} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Title</label>
              <input
                type="text"
                placeholder="e.g. SQLite schema defined"
                value={title}
                onChange={e => setTitle(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Writeup Content</label>
              <textarea
                placeholder="Provide notes/blockers/details..."
                value={content}
                onChange={e => setContent(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm h-32 resize-none"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Tags</label>
              <input
                type="text"
                placeholder="e.g. database, block, roadmap (comma separated)"
                value={tags}
                onChange={e => setTags(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm"
              />
            </div>
            <button
              type="submit"
              className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2 rounded-lg text-sm transition-all shadow-[0_0_15px_rgba(99,102,241,0.2)] cursor-pointer"
            >
              Post Note
            </button>
          </form>
        </div>

        {/* Shared Notebook Logs list */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-lg font-bold text-white">Active Logs</h3>
          {loading ? (
            <div className="text-gray-400 text-sm py-12 text-center">Loading logs...</div>
          ) : writeups.length === 0 ? (
            <div className="glass-panel p-8 rounded-2xl text-center border border-white/5 text-gray-400 text-sm">
              The shared board is empty! Be the first to publish a project update writeup.
            </div>
          ) : (
            <div className="space-y-4 max-h-[600px] overflow-y-auto no-scrollbar pr-1">
              {writeups.map((note) => (
                <div key={note.id} className="glass-panel p-6 rounded-2xl border border-white/5 relative group hover:border-white/10 transition-all space-y-4">
                  {/* Badge & author info */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <div className="p-2 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/10">
                        <User className="w-4 h-4" />
                      </div>
                      <div>
                        <span className="text-sm font-extrabold text-white">@{note.username}</span>
                        <div className="flex items-center gap-2 text-[10px] text-gray-500 mt-0.5">
                          <Calendar className="w-3.5 h-3.5" />
                          {new Date(note.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                        </div>
                      </div>
                    </div>

                    {note.user_id === user?.id && (
                      <button
                        onClick={() => handleDelete(note.id)}
                        className="p-1.5 text-gray-400 hover:text-rose-500 hover:bg-rose-500/10 rounded-lg transition-colors cursor-pointer"
                      >
                        <Trash2 className="w-4.5 h-4.5" />
                      </button>
                    )}
                  </div>

                  {/* Title & Body */}
                  <div className="space-y-2">
                    <h4 className="text-md font-black text-white">{note.title}</h4>
                    <p className="text-gray-300 text-sm whitespace-pre-wrap leading-relaxed bg-dark-bg/40 p-4 rounded-xl border border-white/5 font-mono">{note.content}</p>
                  </div>

                  {/* Tags */}
                  {note.tags && (
                    <div className="flex gap-1.5 flex-wrap">
                      {note.tags.split(',').map((tag, tIdx) => {
                        const cleanTag = tag.trim();
                        if (!cleanTag) return null;
                        return (
                          <span key={tIdx} className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded bg-dark-bg border border-dark-border text-indigo-400">
                            <Tag className="w-3 h-3" />
                            {cleanTag}
                          </span>
                        );
                      })}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
```

---

### Task 11: Analytics Dashboard & GitHub-Style Heatmap Grid
**Files:**
* Create: `/client/src/views/Analytics.tsx`

- [ ] **Step 1: Write Custom Analytics page (with Streak Heatmaps & relative user chart charts)**
We will use SVG rendering to create a gorgeous GitHub-style completion heatmap.
Write `/client/src/views/Analytics.tsx`:
```typescript
import React, { useState, useEffect } from 'react';
import { api } from '../api';
import { useAuth } from '../context/AuthContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { Flame, Medal, Calendar, CheckSquare } from 'lucide-react';

interface UserStat {
  userId: number;
  completedCount: number;
  currentStreak: number;
  maxStreak: number;
  completedDates: string[];
}

export default function Analytics() {
  const { user } = useAuth();
  const [userStats, setUserStats] = useState<Record<string, UserStat>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const data = await api.get('/api/stats');
        setUserStats(data.userStats);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  // Format Recharts data
  const chartData = Object.entries(userStats).map(([name, stats]) => ({
    name: `@${name}`,
    Completions: stats.completedCount
  }));

  // Create local Contribution Heatmap grids (Grid of last 60 days)
  const getHeatmapDays = () => {
    const arr = [];
    const today = new Date();
    for (let i = 59; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      arr.push(d.toISOString().split('T')[0]);
    }
    return arr;
  };

  const heatmapDays = getHeatmapDays();

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold tracking-tight">Performance Stats</h2>
        <p className="text-gray-400 text-sm mt-1">Visualize comparative progress and streak analytics.</p>
      </div>

      {loading ? (
        <div className="text-gray-400 text-sm py-12 text-center">Loading stats...</div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main comparative cards */}
          <div className="lg:col-span-2 space-y-6">
            {/* Summary Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {Object.entries(userStats).map(([name, stats]) => {
                const isMe = name === user?.username;
                return (
                  <div key={name} className={`glass-panel p-6 rounded-2xl border flex flex-col justify-between ${
                    isMe ? 'border-indigo-500/20 shadow-[0_0_15px_rgba(99,102,241,0.05)]' : 'border-white/5'
                  }`}>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-black text-white">@{name} {isMe && '(You)'}</span>
                      <Medal className={`w-5 h-5 ${isMe ? 'text-indigo-400' : 'text-gray-500'}`} />
                    </div>
                    
                    <div className="grid grid-cols-3 gap-2 mt-6">
                      <div className="text-center">
                        <span className="text-[9px] uppercase tracking-wider text-gray-500 font-bold block">Checked</span>
                        <span className="text-xl font-black text-indigo-400 mt-1 block">{stats.completedCount}</span>
                      </div>
                      <div className="text-center border-x border-dark-border">
                        <span className="text-[9px] uppercase tracking-wider text-gray-500 font-bold block">Streak</span>
                        <span className="text-xl font-black text-emerald-400 mt-1 block">{stats.currentStreak}d</span>
                      </div>
                      <div className="text-center">
                        <span className="text-[9px] uppercase tracking-wider text-gray-500 font-bold block">Max Streak</span>
                        <span className="text-xl font-black text-amber-500 mt-1 block">{stats.maxStreak}d</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Heatmaps Container */}
            <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-6">
              <h3 className="text-sm font-bold text-gray-300 uppercase tracking-widest flex items-center gap-2">
                <Calendar className="w-4.5 h-4.5 text-indigo-400" />
                Consistency Heatmap (Last 60 Days)
              </h3>
              
              <div className="space-y-6">
                {Object.entries(userStats).map(([name, stats]) => (
                  <div key={name} className="space-y-2">
                    <span className="text-xs font-semibold text-gray-400">@{name}</span>
                    <div className="flex flex-wrap gap-1">
                      {heatmapDays.map((dayStr) => {
                        const isCompleted = stats.completedDates.includes(dayStr);
                        return (
                          <div
                            key={dayStr}
                            title={`${dayStr}: ${isCompleted ? 'Checked Rule(s)' : 'No completions'}`}
                            className={`w-3.5 h-3.5 rounded-sm transition-all duration-300 hover:scale-110 ${
                              isCompleted
                                ? 'bg-indigo-500 shadow-[0_0_5px_rgba(99,102,241,0.3)]'
                                : 'bg-dark-bg/80 border border-white/5'
                            }`}
                          />
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Bar Chart Container */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 flex flex-col justify-between">
            <div>
              <h3 className="text-sm font-bold text-gray-300 uppercase tracking-widest flex items-center gap-2">
                <CheckSquare className="w-4.5 h-4.5 text-indigo-400" />
                Total Rule Logs Comparison
              </h3>
              <p className="text-xs text-gray-400 mt-1">Relative checks verified across all historic ground rules.</p>
            </div>

            <div className="h-64 mt-6">
              {chartData.length === 0 ? (
                <div className="h-full flex items-center justify-center text-xs text-gray-500">No chart stats to compile.</div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <XAxis dataKey="name" stroke="#6b7280" fontSize={11} tickLine={false} axisLine={false} />
                    <YAxis stroke="#6b7280" fontSize={11} tickLine={false} axisLine={false} />
                    <Tooltip
                      contentStyle={{ backgroundColor: '#161e2e', border: '1px solid #243242', borderRadius: '10px' }}
                      labelStyle={{ color: '#ffffff', fontWeight: 'bold' }}
                    />
                    <Bar dataKey="Completions" radius={[8, 8, 0, 0]}>
                      {chartData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={index === 0 ? '#6366f1' : '#10b981'} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

### Task 12: React App Core Switchboard (App.tsx)
**Files:**
* Create: `/client/src/App.tsx`

- [ ] **Step 1: Write Custom Client state Router panel**
Write `/client/src/App.tsx`:
```typescript
import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './views/Login';
import Layout from './components/Layout';
import Dashboard from './views/Dashboard';
import RulesManager from './views/RulesManager';
import WriteupsBoard from './views/WriteupsBoard';
import Analytics from './views/Analytics';

function AppContent() {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-gray-400 font-semibold tracking-wider uppercase animate-pulse">Initializing Nexus Sync...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Login />;
  }

  return (
    <Layout activeTab={activeTab} setActiveTab={setActiveTab}>
      {activeTab === 'dashboard' && <Dashboard />}
      {activeTab === 'rules' && <RulesManager />}
      {activeTab === 'writeups' && <WriteupsBoard />}
      {activeTab === 'analytics' && <Analytics />}
    </Layout>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}
```

---

## Execution Handoff
Two execution options:
1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach do you prefer?
