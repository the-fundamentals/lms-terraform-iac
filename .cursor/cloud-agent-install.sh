#!/usr/bin/env bash
# Environment build: mise toolchains + dependency-free Terraform gates (no AWS creds).
set -euo pipefail

TF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_mise() {
  if ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | sh
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
  eval "$(mise activate bash)"
}

run_terraform_checks() {
  echo "==> Terraform: fmt -check, init (no backend), validate"
  cd "${TF_ROOT}"
  mise exec -- terraform fmt -check -recursive
  mise exec -- terraform init -backend=false -input=false
  mise exec -- terraform validate
}

main() {
  ensure_mise
  echo "==> mise bootstrap: ${TF_ROOT}"
  cd "${TF_ROOT}"
  mise trust -y
  mise install
  run_terraform_checks
  echo "==> Cloud agent install finished."
}

main "$@"
