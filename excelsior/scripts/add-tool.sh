#!/usr/bin/env bash
# =============================================================================
# Hiren's Boot CD — Excelsior
# add-tool.sh — Add or update a tool in the Excelsior manifest
#
# Usage:
#   bash excelsior/scripts/add-tool.sh [OPTIONS]
#
# Options:
#   --name NAME           Tool name (required)
#   --version VERSION     Tool version (required)
#   --category CATEGORY   Category: disk|network|security|recovery|system|utility
#   --description DESC    Short description
#   --url URL             Download / project URL
#   --license LICENSE     License (e.g. GPL-2.0, MIT)
#   --package PACKAGE     Package name in SystemRescue/Arch repos
#   --interactive         Prompt for all values interactively
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MANIFEST="${REPO_ROOT}/excelsior/tools/MANIFEST.json"

command -v jq &>/dev/null || { echo "Error: 'jq' is required. Install: apt install jq"; exit 1; }

NAME=""; VERSION=""; CATEGORY=""; DESCRIPTION=""; URL=""; LICENSE=""; PACKAGE=""
INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)        NAME="$2"; shift 2 ;;
    --version)     VERSION="$2"; shift 2 ;;
    --category)    CATEGORY="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --url)         URL="$2"; shift 2 ;;
    --license)     LICENSE="$2"; shift 2 ;;
    --package)     PACKAGE="$2"; shift 2 ;;
    --interactive) INTERACTIVE=true; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ "${INTERACTIVE}" == "true" ]]; then
  read -r -p "Tool name: " NAME
  read -r -p "Version: " VERSION
  read -r -p "Category (disk/network/security/recovery/system/utility): " CATEGORY
  read -r -p "Description: " DESCRIPTION
  read -r -p "Project URL: " URL
  read -r -p "License (e.g. GPL-2.0): " LICENSE
  read -r -p "Package name (for pacman/apt): " PACKAGE
fi

[[ -n "${NAME}" ]]     || { echo "Error: --name is required"; exit 1; }
[[ -n "${VERSION}" ]]  || { echo "Error: --version is required"; exit 1; }
[[ -n "${CATEGORY}" ]] || { echo "Error: --category is required"; exit 1; }

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

NEW_ENTRY=$(jq -n \
  --arg name        "${NAME}" \
  --arg version     "${VERSION}" \
  --arg category    "${CATEGORY}" \
  --arg description "${DESCRIPTION}" \
  --arg url         "${URL}" \
  --arg license     "${LICENSE}" \
  --arg package     "${PACKAGE}" \
  --arg added       "${TIMESTAMP}" \
  '{
    name:        $name,
    version:     $version,
    category:    $category,
    description: $description,
    url:         $url,
    license:     $license,
    package:     $package,
    added:       $added
  }')

# Add or update in manifest
UPDATED=$(jq --argjson new "${NEW_ENTRY}" '
  .tools |= (
    if any(.[]; .name == $new.name)
    then map(if .name == $new.name then $new else . end)
    else . + [$new]
    end
  )
' "${MANIFEST}")

echo "${UPDATED}" > "${MANIFEST}"
echo "✅ Tool '${NAME}' added/updated in ${MANIFEST}"
