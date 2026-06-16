#!/bin/sh
# Xboard-Node Complete Hide Instance Uninstaller for Alpine Linux
#
# Usage:
#   sh uninstall-instance.sh --name INSTANCE
#
# Documentation: https://github.com/lei33440/xboard-node-hidden-alpine

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Parse arguments
INSTANCE_NAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        --name) INSTANCE_NAME="$2"; shift 2;;
        --help) cat <<'HELP'
Xboard-Node Complete Hide Instance Uninstaller

Usage:
  sh uninstall-instance.sh --name INSTANCE

Arguments:
  --name INSTANCE   Instance name to uninstall (required)
  --help            Show this help

Examples:
  sh uninstall-instance.sh --name mypanel

Documentation: https://github.com/lei33440/xboard-node-hidden-alpine
HELP
exit 0 ;;
        *) shift;;
    esac
done

# Validate arguments
if [ -z "$INSTANCE_NAME" ]; then
    log_error "Missing --name argument"
    exit 1
fi

SERVICE_NAME="xboard-node-${INSTANCE_NAME}"
HIDDEN_CONFIG_DIR="/etc/.system-cache/${INSTANCE_NAME}"
BINARY_PATH="/usr/local/bin/kernel-update"

echo ""
echo "=============================================="
echo "  Xboard-Node Complete Hide Uninstaller"
echo "=============================================="
echo ""
log_info "Uninstalling instance: ${INSTANCE_NAME}"
echo ""

# Check if instance exists
if [ ! -d "$HIDDEN_CONFIG_DIR" ]; then
    log_error "Instance '${INSTANCE_NAME}' not found!"
    log_info "Available instances:"
    ls -d /etc/.system-cache/*/ 2>/dev/null | while read dir; do
        basename "$dir"
    done
    exit 1
fi

# Read wrapper name
WRAPPER_NAME=""
if [ -f "$HIDDEN_CONFIG_DIR/wrapper" ]; then
    WRAPPER_NAME=$(cat "$HIDDEN_CONFIG_DIR/wrapper")
fi

# Confirm uninstallation
log_warn "This will remove:"
log_warn "  - Service: ${SERVICE_NAME}"
log_warn "  - Config: ${HIDDEN_CONFIG_DIR}"
log_warn "  - Wrapper: /usr/local/bin/${WRAPPER_NAME}"
echo ""

printf "Are you sure? (y/N): "
read -r confirm
case "$confirm" in
    y|Y) ;;
    *) log_info "Aborted." && exit 0 ;;
esac

# Stop and disable service
log_info "Stopping service..."
/etc/init.d/$SERVICE_NAME stop 2>/dev/null || true
pkill -f "${WRAPPER_NAME}" 2>/dev/null || true

rc-update del "$SERVICE_NAME" default 2>/dev/null

# Remove wrapper
if [ -n "$WRAPPER_NAME" ] && [ -f "/usr/local/bin/${WRAPPER_NAME}" ]; then
    log_info "Removing wrapper: ${WRAPPER_NAME}"
    rm -f "/usr/local/bin/${WRAPPER_NAME}"
fi

# Remove files
log_info "Removing files..."
rm -f "/etc/init.d/${SERVICE_NAME}"
# Remove symlink too
if [ -n "$WRAPPER_NAME" ] && [ -L "/usr/local/bin/${SERVICE_NAME}" ]; then
    rm -f "/usr/local/bin/${SERVICE_NAME}"
fi
rm -rf "$HIDDEN_CONFIG_DIR"

# Check if any other instances exist
if [ ! "$(ls -A /etc/.system-cache/ 2>/dev/null)" ]; then
    log_info "No more instances, removing binary..."
    rm -f "$BINARY_PATH"
    rm -f /usr/local/bin/crond-worker /usr/local/bin/ssh-agent /usr/local/bin/system-logger /usr/local/bin/cache-manager /usr/local/bin/sync-daemon 2>/dev/null
fi

echo ""
echo "=============================================="
log_info "Instance '${INSTANCE_NAME}' uninstalled!"
echo "=============================================="
echo ""