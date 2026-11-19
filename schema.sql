-- TelecomLens schema (Postgres)

CREATE TABLE providers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  region TEXT NOT NULL,
  currency TEXT NOT NULL,
  website TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE plans (
  id SERIAL PRIMARY KEY,
  provider_id INT NOT NULL REFERENCES providers(id),
  name TEXT NOT NULL,
  cpu INT,
  ram_mb INT,
  disk_gb INT,
  price_cents INT NOT NULL,
  period TEXT NOT NULL DEFAULT 'monthly',
  is_nat BOOLEAN NOT NULL DEFAULT false,
  stock_status TEXT NOT NULL DEFAULT 'unknown',
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider_id, name)
);

CREATE TABLE price_history (
  id SERIAL PRIMARY KEY,
  plan_id INT NOT NULL REFERENCES plans(id),
  price_cents INT NOT NULL,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE stock_events (
  id SERIAL PRIMARY KEY,
  plan_id INT NOT NULL REFERENCES plans(id),
  type TEXT NOT NULL CHECK (type IN ('restock', 'sold_out')),
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE test_runs (
  id SERIAL PRIMARY KEY,
  plan_id INT NOT NULL REFERENCES plans(id),
  node_id TEXT NOT NULL,
  test_ip INET,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'ok', 'failed')),
  error_type TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE test_results (
  id SERIAL PRIMARY KEY,
  run_id INT NOT NULL REFERENCES test_runs(id),
  latency_p50_ms REAL,
  latency_p95_ms REAL,
  download_mbps REAL,
  upload_mbps REAL,
  packet_loss REAL,
  jitter_ms REAL,
  is_evening_peak BOOLEAN NOT NULL DEFAULT false,
  measured_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_price_history_plan_time ON price_history (plan_id, checked_at DESC);
CREATE INDEX idx_test_results_run ON test_results (run_id);
CREATE INDEX idx_test_runs_status ON test_runs (status, started_at DESC);
