# Nexus Tracker

> A minimal, black-and-white accountability tracker for remote friends. Set ground rules, track daily progress, log writeups, and compete on streaks — all in real-time, across any device.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![React](https://img.shaps.io/badge/React-18.3-61DAFB?logo=react&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5.2-3178C6?logo=typescript&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-06B6D4?logo=tailwindcss&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Express-339933?logo=node.js&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white)

---

## Features

### Dual Accountability System
- Create shared **Ground Rules** (habits, targets, milestones)
- Each user gets their own **personal checklist** of those rules
- Track who did what with a real-time **activity feed**
- Never break the chain with **streak counters**

### Progress Writeups
- Log detailed progress notes with **rich text support**
- Tag entries with `#success`, `#blocker`, `#milestone`
- Shared notebook that both users can read and contribute to
- Author protection — only you can delete your own writeups

### Visual Analytics
- **Progress ring** showing daily completion percentage
- **Streak comparison** — your streak vs. your friend's streak
- **60-day consistency heatmap** (GitHub-style contribution grid)
- **Completion bar chart** comparing total checks

### Minimal Design
- **Pure black & white** — no color, no noise
- **Clean typography** with Inter
- **Fully responsive** — bottom nav on mobile, sidebar on desktop
- **Zero-config deployment** — single Express app serves everything

### Secure & Simple Auth
- JWT-based authentication with 30-day sessions
- Passwords hashed with bcrypt
- Auto-login on return visits

---

## Quick Start

### Prerequisites
- [Node.js](https://nodejs.org/) (v18 or higher)
- npm (comes with Node.js)

### Clone & Run

```bash
git clone https://github.com/yourusername/nexus-tracker.git
cd nexus-tracker
npm run setup
npm start
```

Then open `http://localhost:5000`.

The `setup` command installs all dependencies and builds the frontend once. After that, `npm start` will launch the server directly.

### Development Mode

For active development with hot reload:

```bash
npm run dev
```

This runs both the React dev server (`localhost:3000`) and the backend (`localhost:5000`) simultaneously.

---

## Usage

### For You and Your Friend

1. **Register** — Both users create separate accounts with unique usernames
2. **Create Ground Rules** — Go to the "Ground Rules" tab and add shared rules (e.g., *Code 1 hour*, *Read 30 min*, *Workout*)
3. **Track Daily** — Check off rules on the Dashboard as you complete them
4. **Log Writeups** — Post progress notes with the Quick Writeup Logger or the full Writeups tab
5. **Stay Consistent** — Watch your streak counter grow on the Analytics page
6. **Compete & Collaborate** — See who did what in the real-time activity feed

---

## Deploy to Railway (Free Online Hosting)

Railway offers a free tier with persistent PostgreSQL databases. This is the easiest way to host Nexus Tracker online so your friend can use it too.

### 1. Push to GitHub

```bash
git add .
git commit -m "ready for railway"
git push
```

### 2. Create Railway Project

1. Go to [railway.app](https://railway.app) and sign up (GitHub login)
2. Click **New Project** → **Deploy from GitHub repo**
3. Select your `nexus-tracker` repository
4. Railway will auto-detect it's a Node.js app

### 3. Add PostgreSQL Database

1. In your Railway project, click **New** → **Database** → **Add PostgreSQL**
2. Railway creates the database automatically
3. The `DATABASE_URL` environment variable is added automatically

### 4. Add Environment Variables

In your Railway project settings, add:

| Variable | Value |
|----------|-------|
| `JWT_SECRET` | Any long random string (generate at [jwtsecret.com](https://jwtsecret.com)) |

`DATABASE_URL` is already set by Railway.

### 5. Deploy

Railway auto-deploys on every git push. Your app will be live at a URL like `https://nexus-tracker-production-xyz.up.railway.app`.

### 6. Share with Your Friend

Send them the Railway URL. They can register and use it just like you.

---

## Database Options

| Mode | When Used | Data Persistence |
|------|-----------|------------------|
| **SQLite** (default) | Local development, no `DATABASE_URL` set | File-based (`server/nexus.db`) |
| **PostgreSQL** | Production, `DATABASE_URL` is set | Persistent cloud database |

The app auto-detects which to use. No code changes needed.

---

## Tech Stack

### Frontend
- **React 18** — Component-based UI
- **Vite** — Ultra-fast build tool
- **TypeScript** — Type-safe development
- **Tailwind CSS** — Utility-first styling
- **Lucide React** — Minimal iconography
- **Recharts** — Comparative charts

### Backend
- **Node.js** — JavaScript runtime
- **Express.js** — REST API framework
- **SQLite** — Local development database
- **PostgreSQL** — Production database (via `pg` driver)
- **Socket.io** — Real-time updates
- **jsonwebtoken** — JWT authentication
- **bcryptjs** — Password hashing

---

## Project Structure

```
nexus-tracker/
├── package.json                  # Root orchestration scripts
├── server/
│   ├── package.json
│   ├── .env.example              # Environment variable template
│   ├── src/
│   │   ├── index.js              # Express server entry point
│   │   ├── db.js                 # SQLite database layer
│   │   ├── auth_utils.js         # JWT secret management
│   │   ├── middleware/
│   │   │   └── auth.js           # JWT verification middleware
│   │   └── routes/
│   │       ├── auth.js           # POST /register, POST /login, GET /me
│   │       ├── rules.js          # CRUD for shared ground rules
│   │       ├── checklists.js     # GET /, POST /toggle
│   │       ├── writeups.js       # CRUD for progress notes
│   │       ├── stats.js          # Streaks, heatmap, activity feed
│   │       ├── gamification.js   # XP, levels, achievements
│   │       ├── reactions.js      # Emoji reactions
│   │       └── admin.js          # Admin panel endpoints
│   └── nexus.db                  # SQLite database (auto-created)
└── client/
    ├── package.json
    ├── vite.config.ts            # Dev proxy: /api → localhost:5000
    ├── tailwind.config.js        # Minimal dark theme
    ├── index.html
    └── src/
        ├── main.tsx
        ├── App.tsx               # Auth router + layout switcher
        ├── api.ts                # Fetch wrapper with JWT auto-injection
        ├── index.css             # Tailwind + minimal utilities
        ├── context/
        │   ├── AuthContext.tsx    # Global auth state + auto-login
        │   └── ThemeContext.tsx   # Sound preferences
        ├── components/
        │   ├── Layout.tsx         # Sidebar (desktop) + Bottom nav (mobile)
        │   ├── ProgressRing.tsx   # Animated SVG completion ring
        │   └── ErrorBoundary.tsx  # Error fallback UI
        └── views/
            ├── Login.tsx          # Minimal login/register screen
            ├── Dashboard.tsx      # Checklist, streaks, feed, quick logger
            ├── RulesManager.tsx   # Create/manage ground rules
            ├── WriteupsBoard.tsx  # Full shared notebook
            ├── Analytics.tsx      # Stats, heatmaps, comparison charts
            └── AdminDashboard.tsx # User management panel
```

---

## API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Create new account | No |
| POST | `/api/auth/login` | Authenticate and get JWT | No |
| GET | `/api/auth/me` | Get current user profile | Yes |
| GET | `/api/rules` | List all ground rules | Yes |
| POST | `/api/rules` | Create a new ground rule | Yes |
| DELETE | `/api/rules/:id` | Delete a ground rule | Yes |
| GET | `/api/checklists?date=YYYY-MM-DD` | Get completions for date | Yes |
| POST | `/api/checklists/toggle` | Toggle rule completion | Yes |
| GET | `/api/writeups` | List all writeups | Yes |
| POST | `/api/writeups` | Create a writeup | Yes |
| DELETE | `/api/writeups/:id` | Delete own writeup | Yes |
| GET | `/api/stats` | Get stats, streaks, feed | Yes |
| GET | `/api/gamification/me` | Get XP, level, achievements | Yes |
| GET | `/api/gamification/leaderboard` | Get XP leaderboard | Yes |
| POST | `/api/reactions` | Add emoji reaction | Yes |
| GET | `/api/admin/users` | List all users | Admin |
| DELETE | `/api/admin/users/:id` | Delete a user | Admin |
| POST | `/api/admin/users/:id/toggle-admin` | Toggle admin status | Admin |
| GET | `/api/admin/stats` | Global system stats | Admin |

---

## Environment Variables

Copy `.env.example` to `.env` in the `/server` directory:

```bash
cp server/.env.example server/.env
```

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `JWT_SECRET` | **Yes** (production) | Random per restart | Secret for signing JWT tokens |
| `PORT` | No | `5000` | Server port |

**Important:** If `JWT_SECRET` is not set, the server generates a random secret at runtime. This is secure, but every user will be logged out on every server restart or redeploy. Always set a persistent `JWT_SECRET` in production.

---

## Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature/amazing-thing`
3. **Make your changes** and test locally
4. **Commit**: `git commit -m "feat: add amazing thing"`
5. **Push**: `git push origin feature/amazing-thing`
6. **Open a Pull Request**

### Ideas for Contributions
- Push notifications for streak reminders
- Export data to CSV/JSON
- Multiple accountability groups
- OAuth login (GitHub, Google)
- PWA support for offline access

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

## Acknowledgments

- Built for remote friends who want to hold each other accountable
- Inspired by GitHub's contribution graph for consistency visualization
