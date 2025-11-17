#!/bin/bash

set -euo pipefail

STATE_FILE="/var/lib/hedera/node-state"
LOCK_FILE="/var/lock/hedera-node.lock"
LOG_FILE="/opt/hgcapp/services-hedera/HapiApp2.0/output/node_state_manager.log"
MARKER_FILE="/var/lib/hedera/systemctl-enabled.marker"

current_systemctl_status() {
  echo "===== Systemctl Status of network-node.service =====" | tee -a "$LOG_FILE"
  systemctl status network-node | tee -a "$LOG_FILE"
  echo "=====================================================" | tee -a "$LOG_FILE"
}

# States: UNCONFIGURED, STOPPED, RUNNING, MAINTENANCE
get_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "UNCONFIGURED"
    else
        cat "$STATE_FILE"
    fi
}

set_state() {
    echo "$1" > "$STATE_FILE"
}

case "$1" in
    start)
        current_systemctl_status
        exec 200>"$LOCK_FILE"
        flock -n 200 || exit 1

        STATE=$(get_state)

        case "$STATE" in
            UNCONFIGURED)
                set_state "RUNNING"
                systemctl enable network-node.service | tee -a "$LOG_FILE"
                systemctl restart network-node.service | tee -a "$LOG_FILE"
                touch "$MARKER_FILE"
                ;;
            STOPPED)
                echo "Node is intentionally stopped, not starting" | tee -a "$LOG_FILE"
                exit 0
                ;;
            MAINTENANCE)
                echo "Node is in maintenance mode, not starting" | tee -a "$LOG_FILE"
                exit 0
                ;;
            RUNNING)
                systemctl enable network-node.service | tee -a "$LOG_FILE"
                systemctl restart network-node.service | tee -a "$LOG_FILE"
                touch "$MARKER_FILE"
                ;;
        esac
        sleep 5
        current_systemctl_status
        ;;
    stop)
        current_systemctl_status
        exec 200>"$LOCK_FILE"
        flock -n 200 || exit 1

        set_state "STOPPED"
        systemctl disable --now network-node.service | tee -a "$LOG_FILE"
        rm -f "$MARKER_FILE"
        sleep 5
        current_systemctl_status
        ;;
    maintenance)
        current_systemctl_status
        exec 200>"$LOCK_FILE"
        flock -n 200 || exit 1

        set_state "MAINTENANCE"
        systemctl disable --now network-node.service | tee -a "$LOG_FILE"
        rm -f "$MARKER_FILE"
        sleep 5
        current_systemctl_status
        ;;
esac
