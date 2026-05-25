# Nexus Tracker (Working Copy)

This is a standalone, ready-to-run copy of Nexus Tracker. The frontend is already built — no build step needed.

## Quick Start

### Windows
```bash
cd working-app
npm install --prefix server
node server/src/index.js
```

Or just double-click `start.bat`.

### macOS / Linux
```bash
cd working-app
npm install --prefix server
node server/src/index.js
```

Or run `./start.sh`.

## Open in browser

Once the server is running, go to:

```
http://localhost:5000
```

## First time setup

1. Open `http://localhost:5000`
2. Register two accounts (you and your friend)
3. Go to "Ground Rules" and add shared rules
4. Check them off daily on the Dashboard

## What's included

- `server/` — Express backend + built React frontend (in `server/public/`)
- `server/src/` — API routes, auth, database
- `server/public/` — Pre-built React app (no rebuild needed)
- `start.bat` / `start.sh` — One-click launch scripts

## Requirements

- [Node.js](https://nodejs.org/) v18+

## Notes

- Data is stored in `server/nexus.db` (SQLite, auto-created)
- Default port is `5000`
- To change the JWT secret, copy `.env.example` to `.env` and edit it
