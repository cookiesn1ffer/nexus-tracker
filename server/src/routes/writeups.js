const express = require('express');
const router = express.Router();
const { run, query, get } = require('../db');
const authMiddleware = require('../middleware/auth');

function getIO(req) {
  return req.app.get('io');
}

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

const MAX_WRITEUP_TITLE = 200;
const MAX_WRITEUP_CONTENT = 10000;
const MAX_WRITEUP_TAGS = 200;

router.post('/', authMiddleware, async (req, res) => {
  let { title, content, tags } = req.body;
  if (!title || !content) return res.status(400).json({ error: "Title and content are required" });
  
  // Sanitize: trim and enforce max lengths
  title = String(title).trim().slice(0, MAX_WRITEUP_TITLE);
  content = String(content).trim().slice(0, MAX_WRITEUP_CONTENT);
  tags = tags ? String(tags).trim().slice(0, MAX_WRITEUP_TAGS) : '';

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

    const io = getIO(req);
    if (io) {
      io.to('nexus-room').emit('activity', {
        type: 'writeup',
        id: result.id,
        userId: req.user.id,
        username: req.user.username,
        item_title: title,
        title,
        content,
        tags,
        timestamp: new Date().toISOString()
      });
    }
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
