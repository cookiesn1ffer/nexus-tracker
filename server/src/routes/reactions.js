const express = require('express');
const router = express.Router();
const { run, query } = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/:type/:id', authMiddleware, async (req, res) => {
  try {
    const reactions = await query(
      'SELECT reactions.*, users.username FROM reactions JOIN users ON reactions.user_id = users.id WHERE target_type = ? AND target_id = ?',
      [req.params.type, req.params.id]
    );
    res.json(reactions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const VALID_TARGET_TYPES = ['checklist', 'writeup'];
const VALID_EMOJIS = ['👍', '🔥', '💪', '🎯', '🚀', '⭐'];

router.post('/', authMiddleware, async (req, res) => {
  const { targetType, targetId, emoji } = req.body;
  if (!targetType || !targetId || !emoji) {
    return res.status(400).json({ error: 'Missing fields' });
  }
  if (!VALID_TARGET_TYPES.includes(targetType)) {
    return res.status(400).json({ error: 'Invalid target type' });
  }
  if (!VALID_EMOJIS.includes(emoji)) {
    return res.status(400).json({ error: 'Invalid emoji' });
  }
  if (typeof targetId !== 'number' || targetId <= 0) {
    return res.status(400).json({ error: 'Invalid target ID' });
  }
  
  try {
    // Verify the target exists before allowing reaction
    let targetExists;
    if (targetType === 'checklist') {
      const [check] = await query('SELECT id FROM checklist_logs WHERE id = ?', [targetId]);
      targetExists = !!check;
    } else {
      const [writeup] = await query('SELECT id FROM writeups WHERE id = ?', [targetId]);
      targetExists = !!writeup;
    }
    if (!targetExists) {
      return res.status(404).json({ error: 'Target not found' });
    }

    // Toggle: if exists, delete; if not, create
    const existing = await query(
      'SELECT id FROM reactions WHERE user_id = ? AND target_type = ? AND target_id = ? AND emoji = ?',
      [req.user.id, targetType, targetId, emoji]
    );
    
    if (existing.length > 0) {
      await run('DELETE FROM reactions WHERE id = ?', [existing[0].id]);
      res.json({ reacted: false });
    } else {
      const result = await run(
        'INSERT INTO reactions (user_id, target_type, target_id, emoji) VALUES (?, ?, ?, ?)',
        [req.user.id, targetType, targetId, emoji]
      );
      res.json({ reacted: true, id: result.id });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
