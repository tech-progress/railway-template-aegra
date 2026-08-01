#!/usr/bin/env bash
set -euo pipefail

template_id="${1:?Usage: ./scripts/audit-template.sh TEMPLATE_ID [EXPECTED_STATUS]}"
expected_status="${2:-}"
template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_json="$(railway api 'query Audit($id: String!) { template(id: $id) { name status serializedConfig } }' --var "id=${template_id}" --compact)"
graph_json="$(cd "${template_root}" && ./node_modules/.bin/railway-iac-ts .railway/railway.ts)"

[[ "$(jq -r '.data.template.name' <<<"${template_json}")" == "Aegra agent backend" ]]
[[ -z "${expected_status}" || "$(jq -r '.data.template.status' <<<"${template_json}")" == "${expected_status}" ]]
[[ "$(jq -r '.data.template.serializedConfig.services | [.[] | .name] | sort | join("\n")' <<<"${template_json}")" == $'Aegra\nAegra PostgreSQL\nAegra Redis' ]]

failures=0
for service_name in "Aegra" "Aegra PostgreSQL" "Aegra Redis"; do
  desired="$(jq -c --arg service "${service_name}" '.graph.resources[] | select(.type == "service" and .name == $service)' <<<"${graph_json}")"
  actual="$(jq -c --arg service "${service_name}" '[.data.template.serializedConfig.services[] | select(.name == $service)][0]' <<<"${template_json}")"
  if [[ "$(jq -r '.source.type' <<<"${desired}")" == "image" ]]; then
    [[ "$(jq -r '.source.image' <<<"${actual}")" == "$(jq -r '.source.image' <<<"${desired}")" ]] || failures=$((failures + 1))
  else
    expected_repo="$(jq -r '.source.repo' <<<"${desired}")"
    actual_repo="$(jq -r '.source.repo | sub("^https://github.com/"; "") | sub("\\.git$"; "")' <<<"${actual}")"
    [[ "${actual_repo}" == "${expected_repo}" ]] || failures=$((failures + 1))
    for field in branch rootDirectory; do
      [[ "$(jq -r --arg field "${field}" '.source[$field]' <<<"${actual}")" == "$(jq -r --arg field "${field}" '.source[$field]' <<<"${desired}")" ]] || failures=$((failures + 1))
    done
    [[ "$(jq -r '.build.dockerfilePath' <<<"${actual}")" == "Dockerfile" ]] || failures=$((failures + 1))
  fi
  [[ "$(jq -r '.deploy.healthcheckPath // ""' <<<"${actual}")" == "$(jq -r '.deploy.healthcheckPath // ""' <<<"${desired}")" ]] || failures=$((failures + 1))
  while IFS= read -r variable; do
    key="$(jq -r '.key' <<<"${variable}")"; expected="$(jq -r '.value' <<<"${variable}")"
    value="$(jq -r --arg key "${key}" '.variables[$key].defaultValue // "__MISSING__"' <<<"${actual}")"
    if [[ -z "${expected}" ]]; then
      [[ "${value}" == "__MISSING__" || -z "${value}" ]] || failures=$((failures + 1))
    else
      [[ "${value}" == "${expected}" ]] || failures=$((failures + 1))
    fi
    [[ "$(jq -r --arg key "${key}" '.variables[$key].isOptional // false' <<<"${actual}")" == "false" ]] || failures=$((failures + 1))
  done < <(jq -c --arg service "${service_name}" '.[$service] | to_entries[]' "${template_root}/template-defaults.json")
done

while IFS= read -r service_name; do
  expected="$(jq -c --arg service "${service_name}" '.[$service]' "${template_root}/template-volumes.json")"
  actual="$(jq -c --arg service "${service_name}" '[.data.template.serializedConfig.services[] | select(.name == $service) | .volumeMounts[] | {mountPath,sizeMB}][0]' <<<"${template_json}")"
  [[ "${actual}" == "${expected}" ]] || failures=$((failures + 1))
done < <(jq -r 'keys[]' "${template_root}/template-volumes.json")

expected_port="$(jq -r '.Aegra.publicPort' "${template_root}/template-networking.json")"
actual_port="$(jq -r '[.data.template.serializedConfig.services[] | select(.name == "Aegra") | .networking.serviceDomains["<hasDomain>"].port][0] // 0' <<<"${template_json}")"
[[ "${actual_port}" == "${expected_port}" ]] || failures=$((failures + 1))
(( failures == 0 )) || { echo "Aegra template audit failed with ${failures} mismatch(es)." >&2; exit 1; }
echo "Template ${template_id} matches the Aegra source, pins, defaults, volumes, and networking."
