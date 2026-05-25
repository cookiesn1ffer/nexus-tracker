const express = require('express');
const router = express.Router();
const { query } = require('../db');
const authMiddleware = require('../middleware/auth');

function calculateStreaks(dates, clientToday) {
  if (!dates || dates.length === 0) return { currentStreak: 0, maxStreak: 0 };

  const uniqueDates = [...new Set(dates)].sort(); // ascending YYYY-MM-DD strings
  const dateSet = new Set(uniqueDates);

  // Use client's "today" if provided, otherwise fall back to server local (for backward compat)
  const todayStr = clientToday || (() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  })();

  // Compute yesterday from todayStr
  const [yYear, yMonth, yDay] = todayStr.split('-').map(Number);
  const yesterday = new Date(yYear, yMonth - 1, yDay);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1).padStart(2, '0')}-${String(yesterday.getDate()).padStart(2, '0')}`;

  // Current streak
  let currentStreak = 0;
  if (dateSet.has(todayStr) || dateSet.has(yesterdayStr)) {
    let checkYear = dateSet.has(todayStr) ? yYear : yesterday.getFullYear();
    let checkMonth = dateSet.has(todayStr) ? yMonth : yesterday.getMonth() + 1;
    let checkDay = dateSet.has(todayStr) ? yDay : yesterday.getDate();
    
    while (true) {
      const checkStr = `${checkYear}-${String(checkMonth).padStart(2, '0')}-${String(checkDay).padStart(2, '0')}`;
      if (!dateSet.has(checkStr)) break;
      currentStreak++;
      // Move back one day
      const d = new Date(checkYear, checkMonth - 1, checkDay);
      d.setDate(d.getDate() - 1);
      checkYear = d.getFullYear();
      checkMonth = d.getMonth() + 1;
      checkDay = d.getDate();
    }
  }

  // Max streak
  let maxStreak = 0;
  let currStreak = 0;
  for (let i = 0; i < uniqueDates.length; i++) {
    if (i === 0) {
      currStreak = 1;
    } else {
      const [pY, pM, pD] = uniqueDates[i-1].split('-').map(Number);
      const [cY, cM, cD] = uniqueDates[i].split('-').map(Number);
      const prev = new Date(pY, pM - 1, pD);
      const curr = new Date(cY, cM - 1, cD);
      const diffDays = Math.round((curr - prev) / (1000 * 60 * 60 * 24));
      if (diffDays === 1) {
        currStreak++;
      } else {
        currStreak = 1;
      }
    }
    if (currStreak > maxStreak) maxStreak = currStreak;
  }

  return { currentStreak, maxStreak };
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    // Accept the client's local "today" date via query param
    const clientToday = req.query.today;
    
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

      // Pass client's "today" to streak calculation for timezone accuracy
      const streaks = calculateStreaks(dates, clientToday);
      
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
