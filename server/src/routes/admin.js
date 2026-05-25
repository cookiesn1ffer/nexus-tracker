const express = require('express');
const router = express.Router();
const { run, query, get } = require('../db');
const authMiddleware = require('../middleware/auth');

// Middleware to check if user is admin
const adminMiddleware = async (req, res, next) => {
  try {
    const user = await get('SELECT is_admin FROM users WHERE id = ?', [req.user.id]);
    if (user && user.is_admin) {
      next();
    } else {
      res.status(403).json({ error: "Admin access required" });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get all users
router.get('/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const users = await query('SELECT id, username, is_admin as isAdmin, created_at FROM users ORDER BY created_at DESC');
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a user
router.delete('/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const targetId = req.params.id;
    if (parseInt(targetId) === req.user.id) {
      return res.status(400).json({ error: "You cannot delete yourself" });
    }
    
    // Cleanup user data
    await run('DELETE FROM checklist_logs WHERE user_id = ?', [targetId]);
    await run('DELETE FROM writeups WHERE user_id = ?', [targetId]);
    await run('DELETE FROM user_xp WHERE user_id = ?', [targetId]);
    await run('DELETE FROM achievements WHERE user_id = ?', [targetId]);
    await run('DELETE FROM reactions WHERE user_id = ?', [targetId]);
    await run('DELETE FROM users WHERE id = ?', [targetId]);
    
    res.json({ message: "User and all associated data deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Toggle admin status
router.post('/users/:id/toggle-admin', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { isAdmin } = req.body;
    await run('UPDATE users SET is_admin = ? WHERE id = ?', [isAdmin, req.params.id]);
    res.json({ message: "Admin status updated" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get system stats
router.get('/stats', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const userCount = await get('SELECT COUNT(*) as count FROM users');
    const logCount = await get('SELECT COUNT(*) as count FROM checklist_logs');
    const ruleCount = await get('SELECT COUNT(*) as count FROM rules');
    const adminCount = await get('SELECT COUNT(*) as count FROM users WHERE is_admin = 1');
    
    res.json({
      userCount: parseInt(userCount.count, 10),
      logCount: parseInt(logCount.count, 10),
      ruleCount: parseInt(ruleCount.count, 10),
      adminCount: parseInt(adminCount.count, 10)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
