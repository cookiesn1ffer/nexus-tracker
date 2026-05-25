# Nexus Tracker - Design Specification
**Date:** May 25, 2026
**Topic:** Dual Accountability Tracker & Progress Hub

---

## 1. Overview
Nexus Tracker is a sleek, modern, dark-mode accountability web application designed for two long-distance friends to maintain consistency, set ground rules, log progress writeups, and visualize relative performance and streak statistics.

Rather than a single shared todo list, Nexus Tracker focuses on a **dual-tracking model**:
* **Ground Rules / Targets:** Shared definitions of daily habits, weekly targets, or major milestones.
* **Personal Checklists:** Individual list for each user, representing their completion of the ground rules.
* **Shared Activity Feed:** A chronological timeline of "who checked what" and "who posted which writeup."
* **Progress Analytics:** Competitive/cooperative stats showing streak comparisons, habit completion percentages, and a contribution heatmap.

---

## 2. Architecture & Tech Stack
To minimize deployment complexity while offering a high-performance, real-time-like sync experience, Nexus Tracker uses a **single-deploy full-stack bundle**:
* **Frontend:** Single Page Application (SPA) built with React, Vite, TypeScript, Tailwind CSS, Lucide icons, and Recharts.
* **Backend:** Node.js with Express.js acting as both the REST API server and static asset host.
* **Database:** SQLite (local database file `nexus.db` created automatically) for robust, lightweight, and single-file data storage.
* **Auth:** Secure JWT (JSON Web Tokens) with passwords hashed via `bcryptjs`. Session persists in browser `localStorage`.

---

## 3. Database Schema

### `users`
* `id` (INTEGER, Primary Key, Auto-increment)
* `username` (TEXT, Unique)
* `password_hash` (TEXT)
* `created_at` (DATETIME, Default: CURRENT_TIMESTAMP)

### `rules`
* `id` (INTEGER, Primary Key, Auto-increment)
* `title` (TEXT) - e.g., "Write Code"
* `description` (TEXT) - e.g., "Spend at least 1 hour writing code or planning architecture"
* `frequency` (TEXT) - "daily" | "weekly" | "one-time"
* `difficulty` (TEXT) - "easy" | "medium" | "hard"
* `created_by` (INTEGER, Foreign Key -> `users.id`)
* `created_at` (DATETIME, Default: CURRENT_TIMESTAMP)

### `checklist_logs`
* `id` (INTEGER, Primary Key, Auto-increment)
* `user_id` (INTEGER, Foreign Key -> `users.id`)
* `rule_id` (INTEGER, Foreign Key -> `rules.id`)
* `completed_date` (TEXT) - Format `YYYY-MM-DD` (prevents timezone discrepancies)
* `completed_at` (DATETIME, Default: CURRENT_TIMESTAMP)

### `writeups`
* `id` (INTEGER, Primary Key, Auto-increment)
* `user_id` (INTEGER, Foreign Key -> `users.id`)
* `title` (TEXT)
* `content` (TEXT) - Markdown-supported body
* `tags` (TEXT) - Comma-separated tags (e.g., "milestone,blocker,progress")
* `created_at` (DATETIME, Default: CURRENT_TIMESTAMP)

---

## 4. API Endpoints

### Auth
* `POST /api/auth/register` - Register a new user.
* `POST /api/auth/login` - Authenticate user and return JWT token + user details.
* `GET /api/auth/me` - Validate active token and return current user.

### Rules (Shared)
* `GET /api/rules` - List all shared ground rules.
* `POST /api/rules` - Create a new ground rule.
* `DELETE /api/rules/:id` - Remove a ground rule (soft/hard delete).

### Checklists (Personalized / Synced)
* `GET /api/checklists` - Get checklist logs for a specific user and date.
* `POST /api/checklists/toggle` - Toggle (check/uncheck) a rule completion for a specific date.

### Writeups (Notes)
* `GET /api/writeups` - Retrieve all logs/writeups.
* `POST /api/writeups` - Create a new progress log.
* `DELETE /api/writeups/:id` - Delete a progress log.

### Dashboard & Stats
* `GET /api/stats` - Get consolidated tracking statistics:
  * Streak calculations (current streak, longest streak) for both users.
  * Checklist completion rate charts.
  * History feed (chronological listing of checklist logs and writeups).

---

## 5. UI Layout & User Experience

* **Theme:** Sleek dark-mode workspace. High-contrast slate backgrounds with glowing indigo, emerald, and violet cards.
* **Layout Structure:**
  * **Login/Registration Page:** Clean card layout with floating neon glassmorphism effects.
  * **Dashboard Layout:**
    * **Header:** Current user stats, login details, and a quick logout button.
    * **Sidebar/Tab Navigation:** Quick switching between **Dashboard**, **Rules**, **Writeups**, and **Stats**.
  * **Desktop Dashboard view:**
    * Left panel: Checklist of Ground Rules for Today (with elegant progress ring showing your daily completion).
    * Middle panel: Timeline Activity Feed ("Who Did What" in real-time order).
    * Right panel: Quick Writeup Logger + Streak tracker side-by-side.
  * **Rules View:** Interface to add and view active daily/weekly ground rules.
  * **Writeups View:** Seamless list of shared markdown-friendly progress logs.
  * **Stats View:** Comparison charts (John vs Alex), completion streaks, and activity density grids (GitHub-style contribution grid).

---

## 6. Implementation Stages
1. **Stage 1 (Backend & DB):** Build Node/Express API with SQLite connection, register/login endpoints, rule management, toggling checklist states, writing log files, and analytical calculators.
2. **Stage 2 (Frontend Foundation):** Setup Vite + React + Tailwind CSS with dark theme configurations. Implement responsive routing, login state management, and API client hooks.
3. **Stage 3 (Core Features):** Implement the dual checklists dashboard, interactive rules list, and Markdown writeups board.
4. **Stage 4 (Stats & Polish):** Integrate Recharts for progress metrics, streak metrics, activity grids, and smooth CSS transitions. Build-checks and optimization.
