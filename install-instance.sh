#!/bin/sh
# Xboard-Node Complete Hide Installer for Alpine Linux
#
# Usage:
#   wget -N URL -O install.sh && sh install.sh --name INSTANCE --panel URL --token TOKEN --machine-id ID
#
# Documentation: https://github.com/lei33440/xboard-node-hidden-alpine

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="1.0.0"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Check Alpine
if [ ! -f /etc/alpine-release ]; then
    log_error "This script only supports Alpine Linux"
    exit 1
fi

# Parse arguments
INSTANCE_NAME=""
PANEL_URL=""
TOKEN=""
MACHINE_ID=""
INSTALL_VERSION="latest"

while [ $# -gt 0 ]; do
    case "$1" in
        --name) INSTANCE_NAME="$2"; shift 2;;
        --panel) PANEL_URL="$2"; shift 2;;
        --token) TOKEN="$2"; shift 2;;
        --machine-id) MACHINE_ID="$2"; shift 2;;
        --version) INSTALL_VERSION="$2"; shift 2;;
        --help) cat <<'HELP'
Xboard-Node Complete Hide Installer v1.0.0 (Alpine Linux)

Usage:
  wget -N URL -O install.sh && sh install.sh --name INSTANCE --panel URL --token TOKEN --machine-id ID

Arguments:
  --name NAME       Instance name (required, unique identifier)
  --panel URL       Panel URL (required)
  --token TOKEN     Auth token (required)
  --machine-id ID   Machine ID (required)
  --version VER     Xboard-Node version (default: latest)
  --help            Show this help

Features:
  - Process name hidden (appears as crond-worker/ssh-agent)
  - Binary renamed to kernel-update
  - Config in hidden directory
  - ps -ef | grep xboard shows nothing
  - Alpine OpenRC service management

Examples:
  sh install.sh --name mypanel --panel http://panel.com --token xxx --machine-id 1

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
if [ -z "$PANEL_URL" ]; then
    log_error "Missing --panel argument"
    exit 1
fi
if [ -z "$TOKEN" ]; then
    log_error "Missing --token argument"
    exit 1
fi
if [ -z "$MACHINE_ID" ]; then
    log_error "Missing --machine-id argument"
    exit 1
fi

# Validate instance name
echo "$INSTANCE_NAME" | grep -qE '^[a-zA-Z0-9-]+$' || {
    log_error "Instance name must contain only letters, numbers, and hyphens"
    exit 1
}

# Paths
SERVICE_NAME="xboard-node-${INSTANCE_NAME}"
BINARY_PATH="/usr/local/bin/kernel-update"
# 使用持久化存储路径
HIDDEN_CONFIG_DIR="/etc/.system-cache/${INSTANCE_NAME}"

# Wrapper names pool
WRAPPER_NAMES="crond-worker ssh-agent system-logger cache-manager sync-daemon"

# Banner
echo ""
echo "=============================================="
echo "  Xboard-Node Complete Hide Installer v${VERSION}"
echo "  (Alpine Linux)"
echo "=============================================="
echo ""
log_info "Instance: ${INSTANCE_NAME}"
log_info "Panel: ${PANEL_URL}"
log_info "Machine ID: ${MACHINE_ID}"
echo ""

# Check if instance already exists in hidden location
if [ -d "$HIDDEN_CONFIG_DIR" ]; then
    log_warn "Instance '${INSTANCE_NAME}' already exists!"
    printf "Do you want to overwrite it? (y/N): "
    read -r confirm
    case "$confirm" in
        y|Y) log_info "Overwriting..." ;;
        *) log_info "Aborted." && exit 0 ;;
    esac
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64|arm64) ARCH_NAME="arm64" ;;
    *) log_error "Unsupported architecture: $ARCH" && exit 1 ;;
esac
log_info "Architecture: $ARCH ($ARCH_NAME)"

# Install dependencies
log_step "Installing dependencies..."
apk update >/dev/null 2>&1
apk add curl ca-certificates wget bash >/dev/null 2>&1

# Create persistent directories
mkdir -p /etc/.system-cache
mkdir -p "$HIDDEN_CONFIG_DIR"

# Download binary and rename
if [ ! -f "$BINARY_PATH" ]; then
    log_step "Downloading xboard-node..."

    # 使用空格分隔的字符串代替数组（兼容 sh）
    BASE_URL_1="https://github.com/cedar2025/Xboard-Node/releases"
    BASE_URL_2="https://ghproxy.com/https://github.com/cedar2025/Xboard-Node/releases"
    BASE_URL_3="https://mirror.ghproxy.com/https://github.com/cedar2025/Xboard-Node/releases"

    DOWNLOADED=false
    for BASE in "$BASE_URL_1" "$BASE_URL_2" "$BASE_URL_3"; do
        if [ "$INSTALL_VERSION" = "latest" ]; then
            DOWNLOAD_URL="$BASE/latest/download/xboard-node-linux-$ARCH_NAME"
        else
            DOWNLOAD_URL="$BASE/download/$INSTALL_VERSION/xboard-node-linux-$ARCH_NAME"
        fi
        log_info "Trying: $DOWNLOAD_URL"
        if curl -fsSL --connect-timeout 30 --max-time 300 -o "$BINARY_PATH" "$DOWNLOAD_URL" 2>/dev/null; then
            DOWNLOADED=true
            break
        fi
        log_warn "Download failed, trying next source..."
        sleep 2
    done

    if [ "$DOWNLOADED" = "false" ]; then
        log_error "Failed to download xboard-node after multiple attempts"
        exit 1
    fi

    chmod +x "$BINARY_PATH"
    log_info "Binary downloaded as kernel-update"
else
    log_info "Binary exists, skipping"
fi

# Assign wrapper name
WRAPPER_INDEX=$(ls /usr/local/bin/ 2>/dev/null | grep -E "^(crond-worker|ssh-agent|system-logger|cache-manager|sync-daemon)$" | wc -l)
WRAPPER_NAME=""
i=0
for name in $WRAPPER_NAMES; do
    if [ $i -eq $WRAPPER_INDEX ]; then
        WRAPPER_NAME="$name"
        break
    fi
    i=$((i + 1))
done
if [ -z "$WRAPPER_NAME" ]; then
    WRAPPER_NAME="crond-worker"
fi
log_info "Hidden process name: ${WRAPPER_NAME}"

# Create wrapper script
log_step "Creating hidden wrapper..."
cat > "/usr/local/bin/${WRAPPER_NAME}" <<WRAPPER
#!/bin/bash
CONFIG=${HIDDEN_CONFIG_DIR}/config.yml
exec -a ${WRAPPER_NAME} ${BINARY_PATH} -c \$CONFIG
WRAPPER
chmod +x "/usr/local/bin/${WRAPPER_NAME}"

# Create config
log_step "Creating configuration..."
INSTANCE_ID="$(echo "$PANEL_URL" | sed 's|https\?://||' | tr './' '-')-machine-${MACHINE_ID}-$(date +%s)"
cat > "$HIDDEN_CONFIG_DIR/config.yml" <<EOF
instances:
    - id: ${INSTANCE_ID}
      panel:
        url: ${PANEL_URL}
      machine:
        machine_id: ${MACHINE_ID}
        token: ${TOKEN}
EOF
log_info "Config: ${HIDDEN_CONFIG_DIR}/config.yml"

# Save wrapper info
echo "$WRAPPER_NAME" > "$HIDDEN_CONFIG_DIR/wrapper"

# Create OpenRC service
log_step "Creating OpenRC service..."
mkdir -p /etc/init.d
cat > "/etc/init.d/${SERVICE_NAME}" <<EOF
#!/sbin/openrc-run

name="\${RC_SVCNAME}"
description="System Service - ${INSTANCE_NAME}"
supervisor="supervise-daemon"
command="/usr/local/bin/${WRAPPER_NAME}"
command_args=""
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/dev/null"
error_log="/dev/null"

depend() {
    need net
    after net
}

start() {
    ebegin "Starting \${name}"
    \$supervisor \$command
    eend \$?
}

stop() {
    ebegin "Stopping \${name}"
    pkill -f "${WRAPPER_NAME}" 2>/dev/null
    sleep 1
    eend 0
}

restart() {
    stop
    start
}
EOF
chmod +x "/etc/init.d/${SERVICE_NAME}"

# Add to default runlevel
log_step "Enabling service..."
rc-update add "$SERVICE_NAME" default 2>/dev/null

# Stop existing service if running
log_step "Stopping existing service..."
/etc/init.d/$SERVICE_NAME stop 2>/dev/null || true
sleep 1

# Start service
log_step "Starting service..."
/etc/init.d/$SERVICE_NAME start

# Wait for startup
sleep 3

# Check status
if /etc/init.d/$SERVICE_NAME status >/dev/null 2>&1; then
    echo ""
    echo "=============================================="
    log_info "Instance '${INSTANCE_NAME}' installed!"
    echo "=============================================="
    echo ""
    log_info "Hidden process: ${WRAPPER_NAME}"
    log_info "Binary: ${BINARY_PATH}"
    log_info "Config: ${HIDDEN_CONFIG_DIR}/config.yml"
    echo ""
    log_info "Commands:"
    log_info "  Status:  /etc/init.d/${SERVICE_NAME} status"
    log_info "  Start:   /etc/init.d/${SERVICE_NAME} start"
    log_info "  Stop:    /etc/init.d/${SERVICE_NAME} stop"
    log_info "  Restart: /etc/init.d/${SERVICE_NAME} restart"
    echo ""
    log_warn "Check: ps aux | grep xboard (shows nothing!)"
    log_warn "Check: ps aux | grep ${WRAPPER_NAME} (shows hidden process)"
    echo ""
else
    echo ""
    log_error "Service failed to start"
    exit 1
fi