#!/usr/bin/env bash
set -euo pipefail

api_url="${1:-http://127.0.0.1:2026}"
api_key="${AEGRA_API_KEY:?AEGRA_API_KEY is required}"
auth=(--header "Authorization: Bearer ${api_key}")

ready="$(curl --fail --silent --show-error --retry 30 --retry-delay 2 --retry-all-errors "${api_url}/ready")"
jq -e '.status == "ready"' <<<"${ready}" >/dev/null

unauth_status="$(curl --silent --output /dev/null --write-out '%{http_code}' --request POST \
  --header 'Content-Type: application/json' --data '{}' "${api_url}/threads")"
[[ "${unauth_status}" == "401" ]]

if [[ -n "${AEGRA_SMOKE_THREAD_ID:-}" ]]; then
  state="$(curl --fail --silent --show-error "${auth[@]}" \
    "${api_url}/threads/${AEGRA_SMOKE_THREAD_ID}/state")"
  jq -e --arg expected "${AEGRA_SMOKE_EXPECTED:-railway-smoke}" '
    .values.messages[-1].content | fromjson | .echo == $expected and .status == "completed"
  ' <<<"${state}" >/dev/null
  echo "Aegra authentication and persisted state checks passed for thread ${AEGRA_SMOKE_THREAD_ID}."
  exit 0
fi

message="${AEGRA_SMOKE_MESSAGE:-railway-smoke}"
thread="$(curl --fail --silent --show-error --request POST "${auth[@]}" \
  --header 'Content-Type: application/json' --data '{}' "${api_url}/threads")"
thread_id="$(jq -er '.thread_id' <<<"${thread}")"
run="$(curl --fail --silent --show-error --request POST "${auth[@]}" \
  --header 'Content-Type: application/json' \
  --data "$(jq -nc --arg message "${message}" \
    '{assistant_id:"echo",input:{messages:[{role:"user",content:$message}]}}')" \
  "${api_url}/threads/${thread_id}/runs")"
run_id="$(jq -er '.run_id' <<<"${run}")"

for _ in $(seq 1 60); do
  run="$(curl --fail --silent --show-error "${auth[@]}" \
    "${api_url}/threads/${thread_id}/runs/${run_id}")"
  run_status="$(jq -r '.status' <<<"${run}")"
  case "${run_status}" in
    success) break ;;
    error|timeout|interrupted)
      jq . <<<"${run}" >&2
      exit 1
      ;;
  esac
  sleep 1
done
[[ "${run_status}" == "success" ]]
jq -e --arg expected "${message}" '
  .output.messages[-1].content | fromjson | .echo == $expected and .status == "completed"
' <<<"${run}" >/dev/null

state="$(curl --fail --silent --show-error "${auth[@]}" "${api_url}/threads/${thread_id}/state")"
jq -e --arg expected "${message}" '
  .values.messages[-1].content | fromjson | .echo == $expected and .status == "completed"
' <<<"${state}" >/dev/null

if [[ "${AEGRA_SMOKE_KEEP:-false}" != "true" ]]; then
  curl --fail --silent --show-error --request DELETE "${auth[@]}" \
    "${api_url}/threads/${thread_id}" >/dev/null
fi

echo "Aegra readiness, authentication, Redis-backed execution, PostgreSQL state, and cleanup checks passed."
echo "thread_id=${thread_id} run_id=${run_id}"
