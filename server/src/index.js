require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const { initDb } = require('./db');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Initialize DB
initDb().catch(err => console.error("DB Initialization error:", err));

// Routes
const authRoutes = require('./routes/auth');
const rulesRoutes = require('./routes/rules');
const checklistRoutes = require('./routes/checklists');
const writeupsRoutes = require('./routes/writeups');

app.use('/api/auth', authRoutes);
app.use('/api/rules', rulesRoutes);
app.use('/api/checklists', checklistRoutes);
app.use('/api/writeups', writeupsRoutes);

const statsRoutes = require('./routes/stats');
app.use('/api/stats', statsRoutes);

const gamificationRoutes = require('./routes/gamification');
const reactionRoutes = require('./routes/reactions');
const adminRoutes = require('./routes/admin');

app.use('/api/gamification', gamificationRoutes.router);
app.use('/api/reactions', reactionRoutes);
app.use('/api/admin', adminRoutes);

// Serving built frontend assets if they exist
app.use(express.static(path.join(__dirname, '../public')));

// Basic test route
app.get('/api/test', (req, res) => {
  res.json({ message: "Backend is operational!" });
});

// Wildcard to serve React app
app.get('*', (req, res) => {
  if (require('fs').existsSync(path.join(__dirname, '../public/index.html'))) {
    res.sendFile(path.join(__dirname, '../public/index.html'));
  } else {
    res.status(200).send("Nexus API is running! Frontend is not compiled yet.");
  }
});

const jwt = require('jsonwebtoken');
const { getOrCreateJWTSecret } = require('./auth_utils');

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Socket.io JWT authentication middleware
io.use((socket, next) => {
  const token = socket.handshake.auth.token || socket.handshake.query.token;
  if (!token) {
    return next(new Error('Authentication error: No token provided'));
  }
  try {
    const decoded = jwt.verify(token, getOrCreateJWTSecret());
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error('Authentication error: Invalid token'));
  }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.user?.username || socket.id);

  socket.on('join', (data) => {
    // Only allow authenticated users to join the room
    if (socket.user) {
      socket.join('nexus-room');
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.user?.username || socket.id);
  });
});

// Make io available globally for routes
app.set('io', io);

server.listen(PORT, '0.0.0.0', () => {
  const actualPort = server.address().port;
  console.log(`Server is running on http://0.0.0.0:${actualPort}`);
});
