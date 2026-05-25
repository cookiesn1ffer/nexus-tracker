const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

const root = path.join(__dirname, '..');
const publicDir = path.join(root, 'server', 'public');
const indexHtml = path.join(publicDir, 'index.html');

if (!fs.existsSync(indexHtml)) {
  console.log('Frontend build not found. Building client...');
  try {
    execSync('npm run build --prefix client', { stdio: 'inherit', cwd: root });
    if (fs.existsSync(publicDir)) {
      fs.rmSync(publicDir, { recursive: true });
    }
    fs.renameSync(path.join(root, 'client', 'dist'), publicDir);
    console.log('Build complete.');
  } catch (err) {
    console.error('Build failed:', err.message);
    process.exit(1);
  }
}

console.log('Starting Nexus Tracker on http://localhost:5000 ...\n');

const server = spawn('node', [path.join(root, 'server', 'src', 'index.js')], {
  cwd: root,
  stdio: 'inherit'
});

server.on('exit', (code) => process.exit(code || 0));
process.on('SIGINT', () => { server.kill(); process.exit(0); });
process.on('SIGTERM', () => { server.kill(); process.exit(0); });
