# Deploy and Host Aegra on Railway

Deploy Aegra `0.9.24` as an authenticated, self-hosted Agent Protocol backend with durable PostgreSQL checkpoints and Redis-backed job execution. The template includes a working echo graph, generated bearer authentication, automatic database migrations, and crash recovery without requiring an LLM key.

## About Hosting Aegra

Aegra serves LangGraph applications through the Agent Protocol used by LangGraph clients. This Railway topology keeps PostgreSQL and Redis on the private network while exposing one managed-TLS API domain for threads, runs, streaming events, crons, and store operations.

## Why Deploy Aegra on Railway

Railway supplies the public domain, private service discovery, generated secrets, and persistent volumes. Aegra starts its API and queued workers together, so a graph run can be accepted over HTTP, executed through Redis, checkpointed in PostgreSQL, and recovered after a process restart.

## Common Use Cases

- Host LangGraph agents behind the standard Agent Protocol.
- Give internal applications a persistent threads-and-runs backend.
- Test streaming, cron, store, and human-in-the-loop integrations on infrastructure you control.
- Start from the included key-protected graph and replace it with an application-specific agent.

## Dependencies for Aegra

### Deployment Dependencies

- Aegra CLI and API `0.9.24`, installed from hash-locked official PyPI artifacts
- pgvector on PostgreSQL 18 with a persistent volume
- Redis 8 with password authentication, AOF persistence, and a persistent volume
- No external model credential for the included echo graph
