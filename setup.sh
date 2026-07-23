#!/usr/bin/env bash
# =============================================================================
# Hiren's Boot CD Excelsior — Linux/macOS Setup Wrapper
# =============================================================================
# Shell wrapper for setup.py with Linux/macOS-specific handling.
# Usage:
#   ./setup.sh                         # Interactive
#   ./setup.sh --profile core          # Core profile
#   ./setup.sh --profile full          # Full download
#   ./setup.sh --list-isos             # List ISOs
#   ./setup.sh --dry-run               # Validate only
#   ./setup.sh --isos-only --dest /media/usb/ISOs --profile standard
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ] && command -v tput &>/dev/null; then
    RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4); CYAN=$(tput setaf 6); BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo "  ${CYAN}●${RESET} $*"; }
ok()      { echo "  ${GREEN}✓${RESET} $*"; }
warn()    { echo "  ${YELLOW}!${RESET} $*"; }
err()     { echo "  ${RED}✗${RESET} $*" >&2; }
header()  { echo; echo "  ${BOLD}▶ $*${RESET}"; echo "  $(printf '%.0s─' {1..60})"; }
banner() {
    echo
    echo "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo "  ${BOLD}║   ⚡ Hiren's Boot CD Excelsior — Linux/macOS Setup          ║${RESET}"
    echo "  ║   Modern Multi-OS Bootable USB Toolkit                       ║"
    echo "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

# ── Python detection ──────────────────────────────────────────────────────────
find_python() {
    for candidate in python3 python python3.12 python3.11 python3.10 python3.9 python3.8; do
        if command -v "$candidate" &>/dev/null; then
            version=$("$candidate" --version 2>&1)
            if echo "$version" | grep -qE 'Python 3\.[89]|Python 3\.1[0-9]'; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

install_python_hint() {
    local os
    os=$(uname -s)
    err "Python 3.8+ is required but not found."
    echo
    case "$os" in
        Linux)
            info "Try installing with:"
            echo "    Ubuntu/Debian:  sudo apt install python3"
            echo "    Fedora:         sudo dnf install python3"
            echo "    Arch:           sudo pacman -S python"
            echo "    openSUSE:       sudo zypper install python3"
            ;;
        Darwin)
            info "Try installing with:"
            echo "    Homebrew:  brew install python3"
            echo "    Or download from: https://www.python.org/downloads/"
            ;;
        *)
            info "Download from: https://www.python.org/downloads/"
            ;;
    esac
    echo
    exit 1
}

# ── Root check for Linux USB operations ───────────────────────────────────────
check_sudo() {
    if [ "$(uname -s)" = "Linux" ]; then
        if [ "$EUID" -ne 0 ]; then
            warn "Some Ventoy installation steps require sudo."
            warn "You may be prompted for your password."
        fi
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
banner

header "Checking Requirements"

# Check Python
info "Looking for Python 3.8+..."
if ! PYTHON=$(find_python); then
    install_python_hint
fi
ok "Found: $PYTHON ($("$PYTHON" --version 2>&1))"

# Verify setup.py exists
SETUP_PY="$SCRIPT_DIR/setup.py"
if [ ! -f "$SETUP_PY" ]; then
    err "setup.py not found in: $SCRIPT_DIR"
    err "Please run this script from the Hiren's Boot CD Excelsior directory."
    exit 1
fi

check_sudo

echo
info "Launching setup.py..."
echo

# Pass all arguments through to Python
exec "$PYTHON" "$SETUP_PY" "$@"
