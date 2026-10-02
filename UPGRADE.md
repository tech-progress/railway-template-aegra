# Upgrade

Update `aegra-cli` in `requirements.in`, regenerate `requirements.lock` with hashes, and rebuild from an empty Docker cache. Review upstream migrations and release notes, then repeat clean-volume startup, authenticated execution, initialized restart, and mid-run crash recovery before changing `VERSION`.

Update PostgreSQL or Redis independently only after verifying the target image digest, volume layout, authentication, and Aegra compatibility. Back up PostgreSQL before a major-version change; replacing the image pin does not perform a safe database downgrade.

## 1.0.5 / Aegra 0.10.8

Stop new work and take a consistent PostgreSQL backup (including LangGraph checkpoints) and Redis persistence snapshot before upgrading from 0.9.24. Keep the prior image and configuration with those backups. Startup runs migrations; an old image against a migrated database is not a verified rollback. Rehearse restoring the matching backups in isolation.

Review upstream [0.10.6](https://github.com/aegra/aegra/releases/tag/v0.10.6), [0.10.7](https://github.com/aegra/aegra/releases/tag/v0.10.7), and [0.10.8](https://github.com/aegra/aegra/releases/tag/v0.10.8): checkpoint selection, pending-run recovery, SSE cancellation connection cleanup, durability/checkpoint controls, and interrupt deduplication changed. Bearer auth and the bundled echo graph are unchanged, but this is not a claim of breaking-change-free compatibility.

Test a copy of initialized 0.9 data: read old threads/checkpoints, resume a checkpoint, execute and restart a run, force mid-run recovery, cancel a stream, and exercise interrupts. Clean-state or same-version restart checks alone do not establish an existing-state upgrade; do not switch production until these gates pass.
