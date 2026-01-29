#!/bin/bash
# Disk Usage Alert Script
# Role: Monitor /data partition disk usage and alert when threshold exceeded

set -e

# Default threshold
THRESHOLD=80
DRY_RUN=false

# Help function
function show_help {
  echo "Usage: sudo $0 [options]"
  echo "Options:"
  echo "  --threshold <percent>  Alert threshold in percentage (default: 80)"
  echo "  --dry-run              Print alert to stdout instead of logging"
  echo "  --help                 Show this help message"
  echo ""
  echo "Examples:"
  echo "  sudo $0                              # Check with default 80% threshold"
  echo "  sudo $0 --threshold 90               # Check with 90% threshold"
  echo "  sudo $0 --threshold 85 --dry-run     # Test alert output"
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)
      if [[ -z "$2" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] --threshold requires a numeric value"
        exit 1
      fi
      THRESHOLD="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Get disk usage percentage for /data partition
# Extract from: df /data | tail -1 | awk '{print $5}' | sed 's/%//'
# Fallback to / if /data doesn't exist (for testing on non-production systems)
PARTITION="/data"
if ! df "$PARTITION" >/dev/null 2>&1; then
  PARTITION="/"
fi
USAGE=$(df "$PARTITION" 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")

# Validate usage is a number
if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] Failed to parse disk usage from df output"
  exit 1
fi

# Format timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check if usage exceeds threshold
if [[ $USAGE -gt $THRESHOLD ]]; then
  ALERT_MSG="[ALERT] $TIMESTAMP - /data disk usage: ${USAGE}% (threshold: ${THRESHOLD}%)"
  
  if [[ "$DRY_RUN" == true ]]; then
    # Print to stdout in dry-run mode
    echo "$ALERT_MSG"
  else
    # Append to log file
    LOG_FILE="/var/log/aica-disk-alert.log"
    echo "$ALERT_MSG" >> "$LOG_FILE"
  fi
fi

exit 0
