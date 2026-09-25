#!/bin/sh
# install.sh — setup script for cmdmg
# POSIX sh — no bashisms

set -eu

# --- resolve PROJECT_DIR from script location ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"

CMDMG="${PROJECT_DIR}/cmdmg"
ALIASES_DIR="${PROJECT_DIR}/aliases"
ZSHRC="${HOME}/.zshrc"
BIN_DIR="${HOME}/.local/bin"
BIN_LINK="${BIN_DIR}/cmdmg"

MARKER_START="# >>>> cmdmg (auto-generated — run: cmdmg install) >>>>"
MARKER_END="# <<<< cmdmg <<<<"

# --- helpers ---
die() {
    echo "[install] ERROR: $1" >&2
    exit 1
}

warn() {
    echo "[install] WARN: $1" >&2
}

info() {
    echo "[install] $1"
}

# --- check prerequisites ---
check_prereqs() {
    if [ ! -f "${CMDMG}" ]; then
        die "cmdmg not found at: ${CMDMG}"
    fi

    if [ ! -d "${ALIASES_DIR}" ]; then
        warn "aliases/ directory not found — it will be created when you run 'cmdmg add'"
    fi
}

# --- check if marker block already exists ---
marker_exists() {
    [ -f "${ZSHRC}" ] && grep -qF "${MARKER_START}" "${ZSHRC}" 2>/dev/null
}

# --- remove marker block from .zshrc ---
remove_marker() {
    if [ ! -f "${ZSHRC}" ]; then
        return 0
    fi

    if ! marker_exists; then
        info "no marker block found in ${ZSHRC}"
        return 0
    fi

    tmp="$(mktemp)"
    awk -v start="${MARKER_START}" -v end="${MARKER_END}" '
        $0 == start { skip=1 }
        !skip { print }
        $0 == end { skip=0 }
    ' "${ZSHRC}" > "${tmp}"
    mv "${tmp}" "${ZSHRC}"
    info "removed marker block from ${ZSHRC}"
}

# --- remove symlink ---
remove_symlink() {
    if [ -L "${BIN_LINK}" ]; then
        rm -f "${BIN_LINK}"
        info "removed symlink: ${BIN_LINK}"
    elif [ -f "${BIN_LINK}" ]; then
        warn "${BIN_LINK} exists but is not a symlink — skipping removal"
    fi
}

# --- install ---
do_install() {
    force=0
    for arg in "$@"; do
        case "$arg" in
            --force) force=1 ;;
        esac
    done

    check_prereqs

    # handle marker block
    if marker_exists; then
        if [ "${force}" -eq 1 ]; then
            remove_marker
        else
            die "already installed in ${ZSHRC} (use './install.sh --force' to reinstall)"
        fi
    fi

    # ensure cmdmg is executable
    if [ ! -x "${CMDMG}" ]; then
        chmod +x "${CMDMG}"
        info "made cmdmg executable"
    fi

    # ensure .zshrc exists
    if [ ! -f "${ZSHRC}" ]; then
        touch "${ZSHRC}"
        info "created ${ZSHRC}"
    fi

    # append marker block
    MARKER_LINE="[ -f ${PROJECT_DIR}/cmdmg ] && . ${PROJECT_DIR}/cmdmg init"
    {
        echo ""
        echo "${MARKER_START}"
        echo "${MARKER_LINE}"
        echo "${MARKER_END}"
    } >> "${ZSHRC}"
    info "added marker block to ${ZSHRC}"

    # create symlink in ~/.local/bin/
    mkdir -p "${BIN_DIR}"
    if [ -L "${BIN_LINK}" ] || [ -e "${BIN_LINK}" ]; then
        rm -f "${BIN_LINK}"
    fi
    ln -s "${CMDMG}" "${BIN_LINK}"
    info "created symlink: ${BIN_LINK} → ${CMDMG}"

    echo ""
    info "done! Restart your shell or run: source ${ZSHRC}"

    # check if ~/.local/bin is in PATH
    case ":${PATH}:" in
        *":${BIN_DIR}:"*) : ;;
        *)
            warn "${BIN_DIR} is not in your PATH"
            warn "add this to your .zshrc or .profile: export PATH=\"\${HOME}/.local/bin:\${PATH}\""
            ;;
    esac
}

# --- undo (remove marker block + symlink only) ---
do_undo() {
    remove_marker
    remove_symlink
    info "undo complete — project directory preserved at: ${PROJECT_DIR}"
}

# --- help ---
do_help() {
    cat <<EOF
install.sh — setup script for cmdmg

Usage:
  ./install.sh              Install cmdmg (add marker block + create symlink)
  ./install.sh --force      Reinstall (remove old marker block, add new one)
  ./install.sh --undo       Remove marker block and symlink (keep project dir)
  ./install.sh --help       Show this help
EOF
}

# --- main ---
main() {
    action="install"
    force_flag=""

    for arg in "$@"; do
        case "$arg" in
            --undo)  action="undo" ;;
            --force) force_flag="--force" ;;
            --help|-h) action="help" ;;
            *)
                die "unknown option: ${arg}"
                ;;
        esac
    done

    case "${action}" in
        install) do_install ${force_flag} ;;
        undo)   do_undo ;;
        help)   do_help ;;
    esac
}

main "$@"
