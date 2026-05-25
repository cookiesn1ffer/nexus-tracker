const { spawn } = require('child_process');
const path = require('path');

const root = path.join(__dirname, '..');

const colors = {
  server: '\x1b[36m', // cyan
  client: '\x1b[35m', // magenta
  reset: '\x1b[0m'
};

function prefix(stream, name, color) {
  const prefix = `${color}[${name}]${colors.reset} `;
  let buffer = '';
  stream.on('data', (data) => {
    buffer += data.toString();
    let lines = buffer.split('\n');
    buffer = lines.pop(); // keep incomplete line
    lines.forEach(line => {
      if (line.trim()) console.log(prefix + line);
    });
  });
  stream.on('end', () => {
    if (buffer.trim()) console.log(prefix + buffer);
  });
}

const client = spawn('npm', ['run', 'dev', '--prefix', 'client'], { cwd: root, shell: true });
const server = spawn('node', ['server/src/index.js'], { cwd: root });

prefix(client.stdout, 'CLIENT', colors.client);
prefix(client.stderr, 'CLIENT', colors.client);
prefix(server.stdout, 'SERVER', colors.server);
prefix(server.stderr, 'SERVER', colors.server);

function shutdown() {
  console.log('\nShutting down...');
  client.kill();
  server.kill();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

client.on('exit', (code) => {
  console.log(`Client exited with code ${code}`);
  server.kill();
  process.exit(code || 0);
});

server.on('exit', (code) => {
  console.log(`Server exited with code ${code}`);
  client.kill();
  process.exit(code || 0);
});

console.log('Starting dev servers...\n');
