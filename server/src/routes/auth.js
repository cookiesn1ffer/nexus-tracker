const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { run, get } = require('../db');
const authMiddleware = require('../middleware/auth');
const { JWT_SECRET, getOrCreateJWTSecret } = require('../auth_utils');

router.post('/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: "Please provide username and password" });
  if (password.length < 6) return res.status(400).json({ error: "Password must be at least 6 characters long" });
  if (username.length < 2 || username.length > 30) return res.status(400).json({ error: "Username must be 2-30 characters" });

  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await run(
      'INSERT INTO users (username, password_hash) VALUES (?, ?)',
      [username.trim().toLowerCase(), hash]
    );
    const token = jwt.sign({ id: result.id, username: username.toLowerCase(), isAdmin: 0 }, JWT_SECRET, { expiresIn: '30d' });
    res.status(201).json({ token, user: { id: result.id, username, isAdmin: 0 } });
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

    const token = jwt.sign({ id: user.id, username: user.username, isAdmin: user.is_admin || 0 }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: { id: user.id, username: user.username, isAdmin: user.is_admin || 0 } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await get('SELECT id, username, is_admin as isAdmin, created_at FROM users WHERE id = ?', [req.user.id]);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
