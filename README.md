# Aegra agent backend Railway template

This template deploys [Aegra](https://github.com/aegra/aegra) `0.10.8` as an authenticated Agent Protocol backend with private pgvector/PostgreSQL and Redis services. The current template release is `v1.0.5`.

Aegra runs its HTTP API, Redis-backed worker loops, event broker, lease reaper, and cron scheduler in one service. PostgreSQL persists threads, runs, leases, and LangGraph checkpoints; Redis persists queued work and event transport. The bundled deterministic `echo` graph makes a fresh deployment immediately testable without an LLM credential, and its source is the starting point for your own graph.

Railway builds Aegra from the public `tech-progress/railway-template-aegra` repository on `release-v1`. The container installs official `aegra-cli==0.10.8` and `aegra-api==0.10.8` with transitive artifacts from a hash-locked file, uses Python `3.12.15` on Debian Bookworm, runs as a non-root user, and starts through the upstream `aegra serve` production command.

This maintenance release is prepared locally; publication and existing-deployment migration validation are separate gates. Read [UPGRADE.md](UPGRADE.md) before updating persisted threads or checkpoints.

Local checks on 2026-10-02 passed: template verifier, Docker build with hash-enforced installation, clean PostgreSQL/Redis startup, bearer rejection/authenticated echo execution, same-version restart persistence, SSE execution with synchronous durability, checkpoint history, cooperative interrupt, and forced mid-run crash recovery. Registry index digests were checked with `docker buildx imagetools inspect` using temporary tooling. Upgrading existing 0.9 data, checkpoint replay, stream-disconnect pool cleanup, and Railway deployment/publication were not validated.

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `AEGRA_API_KEY` | generated | Bearer token required for protected Agent Protocol routes. |
| `POSTGRES_PASSWORD` | generated | Protects the private pgvector/PostgreSQL service. |
| `REDIS_PASSWORD` | generated | Protects the private Redis broker. |

Those are the only values you manage; Railway generates them in marketplace deployments, while local Compose requires all three in `.env`. The template also supplies this required runtime contract:

| Variable | Railway default | Purpose |
| --- | --- | --- |
| `AEGRA_CONFIG` | `/app/aegra.json` | Loads the bundled graph and custom authentication hook. |
| `AUTH_TYPE` | `custom` | Enables bearer-token authentication. |
| `DEBUG` / `ENV_MODE` / `LOG_LEVEL` | `false` / `PRODUCTION` / `INFO` | Selects production behavior and logging. |
| `HOST` / `PORT` | `0.0.0.0` / `2026` | Binds the Railway HTTP listener. |
| `SERVER_URL` | Aegra public domain | Advertises the managed-TLS Agent Protocol URL. |
| `POSTGRES_HOST` / `POSTGRES_PORT` | private domain / `5432` | Connects Aegra to private PostgreSQL. |
| `POSTGRES_DB` / `POSTGRES_USER` | `aegra` / `aegra` | Selects the generated database and role. |
| `DB_ECHO_LOG` | `false` | Keeps SQL statement logging disabled. |
| `SQLALCHEMY_POOL_SIZE` / `SQLALCHEMY_MAX_OVERFLOW` | `5` / `5` | Bounds API database connections. |
| `LANGGRAPH_MIN_POOL_SIZE` / `LANGGRAPH_MAX_POOL_SIZE` | `2` / `10` | Bounds checkpoint database connections. |
| `REDIS_BROKER_ENABLED` / `REDIS_URL` | `true` / private authenticated URL | Enables queued workers and event streaming through Redis. |
| `WORKER_COUNT` / `N_JOBS_PER_WORKER` | `2` / `4` | Runs two worker loops with four concurrent jobs each. |
| `CRON_ENABLED` | `true` | Runs the persisted cron scheduler. |
| `ENABLE_PROMETHEUS_METRICS` | `false` | Keeps the metrics route disabled by default. |
| `OTEL_TARGETS` / `OTEL_CONSOLE_EXPORT` | empty / `false` | Disables external and console trace export until configured. |

Copy `AEGRA_API_KEY` from the Aegra service variables and send it as `Authorization: Bearer …`; `/health`, `/live`, and `/ready` intentionally remain available to Railway without authentication.

## Railway use

Deploy the template, wait for `/ready`, then call the bundled graph through any Agent Protocol client using assistant ID `echo`. To install your own graph, replace `src/echo_agent`, update `aegra.json`, and deploy a fork of the public source repository. Keep custom authentication enabled whenever the service has a public domain.

The worker runs inside the Aegra service because upstream does not expose a worker-only process. Use one replica for this baseline: startup applies database migrations, while Redis job leases and the PostgreSQL-backed reaper recover work if that process exits mid-run.

## Local verification

```bash
cp .env.example .env
docker compose up -d --build --wait
AEGRA_API_KEY=your-local-key ./scripts/smoke.sh
docker compose down
```

Set matching passwords and key values in `.env`; never commit it. The release workflow also preserves a smoke thread across restart and forcibly restarts Aegra during a delayed run to prove checkpoint persistence and lease recovery.

## Support boundary

This is a one-replica application baseline for internal agents, prototypes, and small production workloads. It does not configure PostgreSQL or Redis high availability, horizontal Aegra scaling, private-only ingress, an LLM provider, or an observability backend.
