# Changelog

## [1.0.5] - 2026-10-02

- Update Aegra CLI/API to 0.10.8 and regenerate the Python 3.12 hash lock using the existing uv compile command.
- Pin Python 3.12.15 Bookworm to its verified multi-architecture digest; retain PostgreSQL, Redis, bearer auth, and the echo graph.
- Refresh version assertions and upgrade guidance for checkpoint selection, durability, run recovery, and streaming changes. Existing 0.9-state migration and cloud publication remain separate validation gates.

## [1.0.4] - 2026-08-01

- Extended release verification to enforce marketplace metadata limits and exact stored deployment commands.

## [1.0.3] - 2026-08-01

- Documented the complete managed Railway environment contract.
- Moved the standalone distribution check into the self-contained template directory.

## [1.0.2] - 2026-08-01

- Corrected Railway worker, database pool, metrics, and console-export variables to Aegra's exact supported setting names.

## [1.0.1] - 2026-08-01

- Corrected headless draft restoration to update the marketplace display name through Composer settings.
- Added the required marketplace dependency headings and a compliant publish description.

## [1.0.0] - 2026-08-01

- Initial Railway release of Aegra 0.9.24 with authenticated Agent Protocol access.
- Added persistent pgvector/PostgreSQL and authenticated Redis queueing with crash recovery.
- Added a deterministic echo graph so the deployment is useful and verifiable without an external model key.
