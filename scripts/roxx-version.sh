#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# ROXX'S SLAVE — Auto-Version Manager
# Reads current version from .version file, bumps it, tags release
# Called by: install.sh (save_version), devil update, autoupdate
# ══════════════════════════════════════════════════════════════

INSTALL_DIR="${HOME}/.roxx-slave"
VERSION_FILE="${INSTALL_DIR}/.semver"
GITHUB_REPO="mihirshishulkar-SCOPEX/roxxs-slave"

# Get current version (MAJOR.MINOR.PATCH)
get_version() {
  cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "888.0.0"
}

# Bump patch version
bump_patch() {
  local v; v="$(get_version)"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$v"
  patch=$(( ${patch:-0} + 1 ))
  echo "${major}.${minor}.${patch}"
}

# Bump minor version  
bump_minor() {
  local v; v="$(get_version)"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$v"
  minor=$(( ${minor:-0} + 1 ))
  echo "${major}.${minor}.0"
}

# Save new version
save_version() {
  local new_ver="$1"
  mkdir -p "$INSTALL_DIR" 2>/dev/null
  echo "$new_ver" > "$VERSION_FILE"
  echo "$new_ver" > "$INSTALL_DIR/.version"
  echo "$(date '+%F %T')" > "$INSTALL_DIR/.last_updated"
  echo "$new_ver"
}

# Get latest GitHub release version
get_remote_version() {
  curl -fsSL --max-time 10 \
    "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>/dev/null \
    | python3 -c "import json,sys; v=json.load(sys.stdin).get('tag_name','0'); print(v.lstrip('v'))" 2>/dev/null \
    || echo "0"
}

# Main: bump and report
case "${1:-patch}" in
  patch) NEW="$(bump_patch)" ;;
  minor) NEW="$(bump_minor)" ;;
  get)   get_version; exit 0 ;;
  set)   save_version "${2:-888.0.1}"; exit 0 ;;
  *)     NEW="$(bump_patch)" ;;
esac

save_version "$NEW"
echo "$NEW"
