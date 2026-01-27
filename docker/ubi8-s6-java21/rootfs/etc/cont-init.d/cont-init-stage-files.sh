#!/command/with-contenv bash
set -euo pipefail

echo "Starting network-node container initialization..."

if [[ -f /etc/network-node/application.env ]]; then
  echo "Loading application environment from /etc/network-node/application.env"
  set -a
  # shellcheck disable=SC1091
  source /etc/network-node/application.env
  set +a
else
  echo "No application.env found, using default environment"
fi

if [[ -x /etc/network-node/startup/stage_files.sh ]]; then
  echo "Executing stage_files.sh..."
  /etc/network-node/startup/stage_files.sh
else
  echo "stage_files.sh not found or not executable, skipping"
fi

echo "Container initialization complete."
