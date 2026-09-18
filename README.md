# Rails Runner — Deccan Rails Conf

Nostalgic 8-bit / 16-bit arcade platformer for **Deccan Rails Conf**. Attendees scan a QR code, enter a name, and run through **RailsLand** collecting gems, dodging bugs, and answering Rails questions.

The playable MVP is **Level 1: Ruby Valley**. Additional levels are modeled and ready to activate.

This is original work: original character, world, and placeholder pixel art. It is not Mario and does not use Nintendo assets.

## Architecture

```
Rails (landing, registration, admin, JSON API, leaderboard)
└── Phaser 3 + TypeScript (movement, physics, questions overlay, HUD)
        └── frontend/game/
```

- **Rails 8.1** / **Ruby 4.0.1** / **PostgreSQL 16** / **Redis 7**
- **Vite** bundles Phaser. There is no React.
- Scores are computed on the server from game events. The Phaser HUD is a preview only.
- Live TV leaderboard polls every 5 seconds and also listens on Action Cable.

## Requirements

Docker Desktop (Compose v2). You do not need local Ruby, Node, Postgres, or Redis — `bin/dev` starts the stack in containers.

Host ports used: **3000** (Rails) and **3036** (Vite HMR). Postgres and Redis stay on the Docker network so they do not collide with local services.

## Setup

```bash
cp .env.example .env
bin/dev
```

`bin/dev` on the host runs `docker compose up`. Inside the web container it starts Foreman (`Procfile.dev`: Puma + Vite).

Open [http://localhost:3000](http://localhost:3000).

First boot installs gems, npm packages, prepares the database, and seeds questions plus **demo** leaderboard rows.

Useful commands:

```bash
docker compose exec web bin/rails test
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails c
docker compose down
```

## Environment variables

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | PostgreSQL URL used by Rails |
| `TEST_DATABASE_URL` | Isolated test database |
| `REDIS_URL` | Action Cable + cache |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | Admin cabinet login (default `admin` / `changeme`) |
| `APP_HOST` | Public URL used in share copy |
| `CONFERENCE_SLUG` | Which `ConferenceEvent` the QR landing uses |
| `SEED_ON_BOOT` | `true` runs idempotent seeds when the web container starts |

See `.env.example`.

## Running tests

```bash
docker compose exec web bin/rails test
```

Coverage includes player/session creation, question selection and grading, scoring, duplicate events, invalid scores, leaderboard order, completion, and expired sessions.

## Building Phaser assets

Development: Vite runs next to Puma and hot-reloads `frontend/`.

Production image target builds with `bundle exec vite build` (see `Dockerfile`).

Entry points:

- `frontend/entrypoints/game.ts` — Phaser bootstrap
- `frontend/entrypoints/leaderboard.ts` — TV board polling + Action Cable

## Admin access

[http://localhost:3000/admin/login](http://localhost:3000/admin/login)

From admin you can manage players, questions (CRUD + activate), levels, scoring, game duration / lives / question frequency / difficulty progression, inspect suspicious runs, unpublish the leaderboard, view analytics, and export CSV.

Email is visible to admins only. It is never rendered on the public leaderboard.

## Leaderboard

- `/leaderboard` — conference TV / projector board (large type, auto-refresh)
- `/leaderboard/today` — today's scores
- `GET /api/v1/leaderboard?scope=conference|today&limit=10`

Demo seed rows are tagged `demo: true`. Turn off **Include demo scores** in admin scoring config before the real event.

## How to add questions

Admin → Questions → New question.

Choices (one per line):

```
A. User.all.each
B. User.includes(:orders)
C. User.all.to_a
D. User.pluck(:orders)
```

Set **Correct key** to `B`. Categories and difficulties are validated on the model (`easy` / `medium` / `hard`).

Questions live in PostgreSQL, not in TypeScript.

## How to create a conference event

```ruby
event = ConferenceEvent.create!(
  name: "Deccan Rails Conf",
  slug: "deccan-rails-conf",
  location: "Hyderabad",
  active: true
)
GameConfiguration.create!(conference_event: event)
```

Point `CONFERENCE_SLUG` at that slug and restart `web`.

## How to replace pixel-art assets

Placeholder sprites are generated at runtime in `frontend/game/assets/pixelArt.ts` from original pixel maps (runner, gems, bugs, tracks). To drop in designer art:

1. Add PNGs under `frontend/game/assets/images/`
2. Load them in `PreloadScene`
3. Keep the same texture keys (`player`, `ruby`, `rails`, `boost`, `special`, `bug`, `prod-bug`, `debt`, `ground`, `platform`, `flag`)

Audio is generated with the Web Audio API after the first tap (mobile autoplay rules). Mute is on-screen.

## Deployment

The `Dockerfile` has a `production` target (Rails + built Vite assets + Thruster). Run it with managed PostgreSQL and Redis, and set `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY_BASE`, `ADMIN_PASSWORD`, `APP_HOST`, and `CONFERENCE_SLUG`.

QR codes should point at the public origin (for example `https://game.deccanrailsconf.com`). There is no attendee login.

## Game loop

Register → instructions → play Ruby Valley (left / right / jump, 3 lives, ~90 seconds) → Rails questions → finish → server-side score → result → leaderboard → play again.

Keyboard: arrows + space. Touch pads are ≥ 44px.
