import {
  defineRailway,
  github,
  group,
  preserve,
  project,
  service,
  volume,
} from "railway/iac";

const SOURCE = github("tech-progress/railway-template-aegra", {
  branch: "release-v1",
  rootDirectory: "/",
});
const POSTGRES_IMAGE =
  "pgvector/pgvector:pg18@sha256:691673308c99d2161ba298736f3147f1f22d79de2fb7ec93ae9b4afcab870b62";
const REDIS_IMAGE =
  "redis:8-alpine@sha256:e8eb6f2980c06c6a25c08f62cb2e00dc7d2fead9aa492cfdd8b54a42109ae0f2";

export default defineRailway(() => {
  const postgresData = volume("Aegra PostgreSQL Data", { sizeMB: 5_000 });
  const redisData = volume("Aegra Redis Data", { sizeMB: 1_000 });

  const postgres = service("Aegra PostgreSQL", {
    source: { image: POSTGRES_IMAGE },
    volumeMounts: { "/var/lib/postgresql": postgresData },
    env: {
      POSTGRES_DB: "aegra",
      POSTGRES_USER: "aegra",
      POSTGRES_PASSWORD: preserve(),
    },
  });

  const redis = service("Aegra Redis", {
    source: { image: REDIS_IMAGE },
    start:
      "/bin/sh -ec 'exec redis-server --appendonly yes --requirepass \"$REDIS_PASSWORD\"'",
    volumeMounts: { "/data": redisData },
    env: { REDIS_PASSWORD: preserve() },
  });

  const aegra = service("Aegra", {
    source: SOURCE,
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile",
      watchPatterns: ["/**", "!/FINDINGS.md"],
    },
    healthcheck: "/ready",
    healthcheckTimeout: 300,
    env: {
      AEGRA_CONFIG: "/app/aegra.json",
      AEGRA_API_KEY: preserve(),
      AUTH_TYPE: "custom",
      DEBUG: "false",
      ENV_MODE: "PRODUCTION",
      LOG_LEVEL: "INFO",
      HOST: "0.0.0.0",
      PORT: "2026",
      SERVER_URL: "https://${{Aegra.RAILWAY_PUBLIC_DOMAIN}}",
      POSTGRES_DB: postgres.env.POSTGRES_DB,
      POSTGRES_HOST: postgres.env.RAILWAY_PRIVATE_DOMAIN,
      POSTGRES_PASSWORD: postgres.env.POSTGRES_PASSWORD,
      POSTGRES_PORT: "5432",
      POSTGRES_USER: postgres.env.POSTGRES_USER,
      DB_ECHO_LOG: "false",
      SQLALCHEMY_POOL_SIZE: "5",
      SQLALCHEMY_MAX_OVERFLOW: "5",
      LANGGRAPH_MIN_POOL_SIZE: "2",
      LANGGRAPH_MAX_POOL_SIZE: "10",
      REDIS_BROKER_ENABLED: "true",
      REDIS_URL:
        "redis://:${{Aegra Redis.REDIS_PASSWORD}}@${{Aegra Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/0",
      WORKER_COUNT: "2",
      N_JOBS_PER_WORKER: "4",
      CRON_ENABLED: "true",
      ENABLE_PROMETHEUS_METRICS: "false",
      OTEL_CONSOLE_EXPORT: "false",
      OTEL_TARGETS: "",
    },
  });

  return project("Aegra agent backend", {
    resources: [
      group("Application", [aegra]),
      group("Data", [postgres, postgresData, redis, redisData]),
    ],
  });
});
