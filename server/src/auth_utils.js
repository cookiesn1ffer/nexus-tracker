const crypto = require('crypto');

function getOrCreateJWTSecret() {
  if (process.env.JWT_SECRET) return process.env.JWT_SECRET;
  // Fallback to a random key if not provided in env, 
  // but note this will invalidate tokens on server restart
  return crypto.randomBytes(64).toString('hex');
}

const JWT_SECRET = getOrCreateJWTSecret();

module.exports = {
  JWT_SECRET,
  getOrCreateJWTSecret
};
