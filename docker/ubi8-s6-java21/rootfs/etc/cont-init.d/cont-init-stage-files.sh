#!/command/with-contenv bash
set -euo pipefail

if [[ -f /etc/network-node/application.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source /etc/network-node/application.env
  set +a
fi

if [[ -x /etc/network-node/startup/stage_files.sh ]]; then
  /etc/network-node/startup/stage_files.sh
else
  echo "stage_files.sh not found or not executable, skipping"
fi
