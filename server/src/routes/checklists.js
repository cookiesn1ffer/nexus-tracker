const express = require('express');
const router = express.Router();
const { run, query, get } = require('../db');
const authMiddleware = require('../middleware/auth');
const { awardXP } = require('./gamification');

function getIO(req) {
  return req.app.get('io');
}

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
    // Try delete first - if it existed, it was "on", now it's "off"
    const delResult = await run(
      'DELETE FROM checklist_logs WHERE user_id = ? AND rule_id = ? AND completed_date = ?',
      [userId, ruleId, date]
    );

    let checked;
    let xpResult = null;

    if (delResult.changes > 0) {
      checked = false;
      xpResult = await awardXP(req.user.id, -25);
      res.json({ checked: false, ruleId, xpResult });
    } else {
      // It didn't exist, insert it (turn "on")
      try {
        await run(
          'INSERT INTO checklist_logs (user_id, rule_id, completed_date) VALUES (?, ?, ?)',
          [userId, ruleId, date]
        );
        checked = true;
        xpResult = await awardXP(req.user.id, 25);
        res.json({ checked: true, ruleId, xpResult });
      } catch (err) {
        // Race condition: another request inserted between our DELETE and INSERT
        if (err.message && err.message.includes('UNIQUE')) {
          checked = true;
          res.json({ checked: true, ruleId });
        } else {
          throw err;
        }
      }
    }

    const io = getIO(req);
    if (io) {
      io.to('nexus-room').emit('activity', {
        type: 'checklist',
        userId: req.user.id,
        username: req.user.username,
        ruleId,
        checked,
        xpResult,
        timestamp: new Date().toISOString()
      });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
