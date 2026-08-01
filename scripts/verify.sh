#!/usr/bin/env bash
set -euo pipefail

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required_files=(
  .dockerignore .env.example .gitignore .railway/railway.ts aegra.json auth.py
  CHANGELOG.md Dockerfile LICENSE_REVIEW.md MARKETPLACE.md PUBLISHING.md
  README.md SUPPORT.md UPGRADE.md VERSION bun.lock compose.yaml package.json
  requirements.in requirements.lock scripts/audit-template.sh
  scripts/check-standalone.sh scripts/restore-template-draft.sh scripts/smoke.sh scripts/verify.sh
  src/echo_agent/__init__.py src/echo_agent/graph.py template-defaults.json
  template-descriptions.json template-networking.json template-volumes.json
)
for file in "${required_files[@]}"; do
  test -f "${template_root}/${file}" || { echo "Missing required file: ${file}" >&2; exit 1; }
done

version="$(<"${template_root}/VERSION")"
[[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
grep -Eq "^## \[${version//./\\.}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" "${template_root}/CHANGELOG.md"
for file in README.md PUBLISHING.md; do
  grep -Fq "current template release is \`v${version}\`" "${template_root}/${file}"
done
for heading in '# Deploy and Host' '## About Hosting' '## Why Deploy' '## Common Use Cases' '## Dependencies for' '### Deployment Dependencies'; do
  grep -Fq "${heading}" "${template_root}/MARKETPLACE.md"
done
publish_description="Authenticated Aegra backend with durable PostgreSQL and Redis."
(( ${#publish_description} <= 75 ))

POSTGRES_PASSWORD=verify-postgres REDIS_PASSWORD=verify-redis AEGRA_API_KEY=verify-aegra \
  docker compose -f "${template_root}/compose.yaml" config --quiet
for file in template-defaults.json template-descriptions.json template-networking.json template-volumes.json aegra.json; do
  jq empty "${template_root}/${file}"
done
for file in "${template_root}"/scripts/*.sh; do bash -n "${file}"; done
python3 -m py_compile "${template_root}/auth.py" "${template_root}/src/echo_agent/graph.py"

graph_json="$(cd "${template_root}" && ./node_modules/.bin/railway-iac-ts .railway/railway.ts)"
jq -e '
  .graph.resources |
  ([.[] | select(.type == "service") | .name] | sort) ==
    ["Aegra", "Aegra PostgreSQL", "Aegra Redis"] and
  ([.[] | select(.type == "volume")] | length) == 2 and
  ([.[] | select(.name == "Aegra")][0].source.repo == "tech-progress/railway-template-aegra") and
  ([.[] | select(.name == "Aegra")][0].source.branch == "release-v1") and
  ([.[] | select(.name == "Aegra")][0].build.dockerfilePath == "Dockerfile") and
  ([.[] | select(.name == "Aegra")][0].deploy.healthcheckPath == "/ready") and
  ([.[] | select(.name == "Aegra")][0].variables |
    .SQLALCHEMY_POOL_SIZE.value == "5" and
    .SQLALCHEMY_MAX_OVERFLOW.value == "5" and
    .LANGGRAPH_MIN_POOL_SIZE.value == "2" and
    .LANGGRAPH_MAX_POOL_SIZE.value == "10" and
    .WORKER_COUNT.value == "2" and
    .N_JOBS_PER_WORKER.value == "4" and
    .ENABLE_PROMETHEUS_METRICS.value == "false" and
    .OTEL_CONSOLE_EXPORT.value == "false")
' <<<"${graph_json}" >/dev/null

jq -e --slurpfile descriptions "${template_root}/template-descriptions.json" '
  (to_entries | all(. as $service |
    (.value | keys | sort) == ($descriptions[0][$service.key] | keys | sort))) and
  ((.Aegra | [has("DB_POOL_MIN_SIZE"), has("REDIS_WORKER_COUNT"), has("METRICS_ENABLED")] | any) | not)
' "${template_root}/template-defaults.json" >/dev/null

grep -Fq 'aegra-cli==0.9.24' "${template_root}/requirements.lock"
for pin in \
  d50fb7611f86d04a3b0471b46d7557818d88983fc3136726336b2a4c657aa30b \
  691673308c99d2161ba298736f3147f1f22d79de2fb7ec93ae9b4afcab870b62 \
  e8eb6f2980c06c6a25c08f62cb2e00dc7d2fead9aa492cfdd8b54a42109ae0f2; do
  grep -Rqs "${pin}" "${template_root}/Dockerfile" "${template_root}/compose.yaml" "${template_root}/.railway/railway.ts"
done

if find "${template_root}" -type f \( -name .env -o -name '*.local' \) -print -quit | grep -q .; then
  echo "Local secret file found in the template directory." >&2
  exit 1
fi
echo "Aegra template structure, source pins, dependency lock, variables, volumes, and networking are valid."
