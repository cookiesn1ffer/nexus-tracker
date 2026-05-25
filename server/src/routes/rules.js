const express = require('express');
const router = express.Router();
const { run, query, get } = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const rules = await query('SELECT rules.*, users.username as creator FROM rules LEFT JOIN users ON rules.created_by = users.id ORDER BY rules.created_at DESC');
    res.json(rules);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const MAX_RULE_TITLE = 200;
const MAX_RULE_DESCRIPTION = 1000;

router.post('/', authMiddleware, async (req, res) => {
  let { title, description, frequency, difficulty } = req.body;
  if (!title || !frequency || !difficulty) {
    return res.status(400).json({ error: "Title, frequency and difficulty are required" });
  }

  // Sanitize input
  title = String(title).trim().slice(0, MAX_RULE_TITLE);
  description = description ? String(description).trim().slice(0, MAX_RULE_DESCRIPTION) : '';

  try {
    const result = await run(
      'INSERT INTO rules (title, description, frequency, difficulty, created_by) VALUES (?, ?, ?, ?, ?)',
      [title, description, frequency, difficulty, req.user.id]
    );
    res.status(201).json({ id: result.id, title, description, frequency, difficulty, created_by: req.user.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    // Verify the rule exists and was created by this user
    const rule = await get('SELECT created_by FROM rules WHERE id = ?', [req.params.id]);
    if (!rule) return res.status(404).json({ error: "Rule not found" });
    if (rule.created_by !== req.user.id) {
      return res.status(403).json({ error: "You can only delete rules you created" });
    }

    // Delete logs associated with rule first to avoid cascade issues
    await run('DELETE FROM checklist_logs WHERE rule_id = ?', [req.params.id]);
    const result = await run('DELETE FROM rules WHERE id = ?', [req.params.id]);
    res.json({ message: "Rule deleted successfully", result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
