# TelecomLens

A live VPS picker that runs evening-peak tests, tracks prices and stock, and updates rankings daily.

It tracks ByteVirt, DigitalVirt and Tizz plans, and ranks them by measured performance — not by marketing claims.

## Stack

- **Site:** Next.js 15 + TypeScript + Tailwind CSS, deployed on Vercel
- **Database:** Postgres on Neon, with Prisma
- **Runner:** Python 3.12 worker on Fly.io, separate from the site
- **Charts:** Recharts for latency / speed history

## Database

See `schema.sql`. Core tables:

- `providers` — name, region, currency, website
- `plans` — cpu, ram, disk, price, period, NAT or dedicated, stock status
- `price_history` — price changes over time
- `stock_events` — restock / sold_out events
- `test_runs` — one run per plan per test slot
- `test_results` — latency p50/p95, download, upload, packet loss, jitter

Ranking weights: 40% evening-peak p95 latency, 30% download, 20% price, 10% stock stability.

## Runner

The runner lives in `runner/`. APScheduler triggers tests at 20:00, 21:00 and 22:00 CST. Each job goes into a Postgres queue table.

- **Scraper layer:** per-provider adapters. Playwright headless Chromium with stealth for JS pages, fallback to curl + BeautifulSoup. HTML diffs trigger a fix task instead of silently returning stale prices.
- **Tester layer:** ICMP + TCP/443 ping, mtr, and curl download tests against the provider test IP. Raw results are stored, not just an average.
- **Forum adapter:** pulls third-party review posts, extracts claimed latency/speed, and flags them as unverified vs. measured results.

## Git workflow

- `main` is protected, no direct pushes.
- Daily data: `bot/test-YYYY-MM-DD`
- Fixes: `bot/fix-<provider>-<date>`
- Every change goes through a PR, squash-merge only.
- CI on every PR: typecheck, unit tests for ranking logic, Playwright smoke test, data validation (reject latency 0, download >10x yesterday, plans count 0).
- Devin Review reviews first, then a human approves in the Needs You inbox. If CI fails twice, the provider is marked `degraded` and the last verified ranking stays live. No fake data is published when a run fails.

## Roadmap

- **Week 1:** DB + site skeleton with 3 providers
- **Week 2:** Runner + evening-peak tests live
- **Week 3:** Ranking engine + history charts
- **Week 4:** Restock alerts + 5 more providers

## Status

Early build. The Devin Bot owns the repo and opens a PR daily with new test data.
