const express = require('express');
const router = express.Router();
const { run, query, get } = require('../db');
const authMiddleware = require('../middleware/auth');

const LEVEL_THRESHOLDS = [0, 100, 250, 500, 900, 1500, 2300, 3300, 4600, 6200, 8200];
const RANK_TITLES = ['Novice', 'Apprentice', 'Adept', 'Skilled', 'Expert', 'Master', 'Grandmaster', 'Legend', 'Mythic', 'Transcendent', 'Immortal'];

function getLevelFromXP(xp) {
  let level = 1;
  for (let i = 1; i < LEVEL_THRESHOLDS.length; i++) {
    if (xp >= LEVEL_THRESHOLDS[i]) level = i + 1;
    else break;
  }
  return level;
}

function getRankTitle(level) {
  return RANK_TITLES[Math.min(level - 1, RANK_TITLES.length - 1)];
}

function getXPForNextLevel(level) {
  return LEVEL_THRESHOLDS[Math.min(level, LEVEL_THRESHOLDS.length - 1)];
}

// Award XP and check level up
async function awardXP(userId, amount) {
  let xpRow = await get('SELECT * FROM user_xp WHERE user_id = ?', [userId]);
  if (!xpRow) {
    const initialXP = Math.max(0, amount);
    await run('INSERT INTO user_xp (user_id, total_xp, level) VALUES (?, ?, ?)', [userId, initialXP, 1]);
    xpRow = { total_xp: initialXP, level: 1 };
  } else {
    const newXP = Math.max(0, xpRow.total_xp + amount);
    await run('UPDATE user_xp SET total_xp = ? WHERE user_id = ?', [newXP, userId]);
    xpRow.total_xp = newXP;
  }

  const calculatedLevel = getLevelFromXP(xpRow.total_xp);
  if (calculatedLevel > xpRow.level) {
    await run('UPDATE user_xp SET level = ? WHERE user_id = ?', [calculatedLevel, userId]);
    return { leveledUp: true, regressed: false, newLevel: calculatedLevel, oldLevel: xpRow.level };
  }
  return { leveledUp: false, regressed: false };
}

// Award achievement
async function awardAchievement(userId, badgeId, badgeName, badgeIcon) {
  const existing = await get('SELECT id FROM achievements WHERE user_id = ? AND badge_id = ?', [userId, badgeId]);
  if (!existing) {
    await run('INSERT INTO achievements (user_id, badge_id, badge_name, badge_icon) VALUES (?, ?, ?, ?)',
      [userId, badgeId, badgeName, badgeIcon]);
    return true;
  }
  return false;
}

// Get user gamification stats
router.get('/me', authMiddleware, async (req, res) => {
  try {
    let xpRow = await get('SELECT * FROM user_xp WHERE user_id = ?', [req.user.id]);
    if (!xpRow) {
      await run('INSERT INTO user_xp (user_id, total_xp, level) VALUES (?, ?, ?)', [req.user.id, 0, 1]);
      xpRow = { total_xp: 0, level: 1 };
    }

    const achievements = await query('SELECT * FROM achievements WHERE user_id = ? ORDER BY unlocked_at DESC', [req.user.id]);
    const nextLevelXP = getXPForNextLevel(xpRow.level);

    res.json({
      totalXP: xpRow.total_xp,
      level: xpRow.level,
      rankTitle: getRankTitle(xpRow.level),
      nextLevelXP,
      progressToNext: nextLevelXP > 0 ? Math.round((xpRow.total_xp / nextLevelXP) * 100) : 100,
      achievements
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get leaderboard
router.get('/leaderboard', authMiddleware, async (req, res) => {
  try {
    const leaderboard = await query(`
      SELECT users.username, user_xp.total_xp, user_xp.level
      FROM user_xp
      JOIN users ON user_xp.user_id = users.id
      ORDER BY user_xp.total_xp DESC
    `);
    res.json(leaderboard.map(u => ({
      ...u,
      rankTitle: getRankTitle(u.level)
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = { router, awardXP, awardAchievement, getLevelFromXP, getRankTitle };
