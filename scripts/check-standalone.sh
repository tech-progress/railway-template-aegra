#!/usr/bin/env bash
set -euo pipefail

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
monorepo_root="$(cd "${template_root}/.." && pwd)"
standalone_dir="${1:-$(cd "${monorepo_root}/.." && pwd)/railway-template-aegra}"

if [[ ! -d "${standalone_dir}/.git" ]]; then
  echo "Standalone Aegra repository not found at ${standalone_dir}." >&2
  exit 1
fi
if [[ -e "${standalone_dir}/FINDINGS.md" ]]; then
  echo "FINDINGS.md must remain private to the monorepo." >&2
  exit 1
fi
diff -qr --exclude=.git --exclude=FINDINGS.md --exclude=node_modules --exclude=__pycache__ "${template_root}" "${standalone_dir}"
echo "Aegra monorepo and standalone distribution files match."
