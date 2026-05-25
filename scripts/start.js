const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const publicDir = path.join(__dirname, '..', 'server', 'public');
const indexHtml = path.join(publicDir, 'index.html');

// If built frontend doesn't exist, build it
if (!fs.existsSync(indexHtml)) {
  console.log('Frontend build not found. Building client...');
  try {
    execSync('npm run build --prefix client', { stdio: 'inherit', cwd: path.join(__dirname, '..') });
    
    // Move dist to server/public
    if (fs.existsSync(publicDir)) {
      fs.rmSync(publicDir, { recursive: true });
    }
    fs.renameSync(path.join(__dirname, '..', 'client', 'dist'), publicDir);
    console.log('Build complete. Starting server...');
  } catch (err) {
    console.error('Build failed:', err.message);
    process.exit(1);
  }
}

// Start the server
console.log('Starting Nexus Tracker server...');
require('../server/src/index.js');
