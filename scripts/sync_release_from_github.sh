#!/usr/bin/env bash
# ==============================================================================
# BareStats Homebrew Tap Release Synchronization Script
# Automatically syncs Formula/barestats.rb and Casks/barestats.rb with GitHub
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FORMULA_FILE="${TAP_ROOT}/Formula/barestats.rb"
CASK_FILE="${TAP_ROOT}/Casks/barestats.rb"

REPO="chakrank/BareStats"
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'barestats-sync')"
trap 'rm -rf "${TMP_DIR}"' EXIT

AUTH_HEADER=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER=(-H "Authorization: token ${GITHUB_TOKEN}")
elif [ -n "${HOMEBREW_TAP_TOKEN:-}" ]; then
    AUTH_HEADER=(-H "Authorization: token ${HOMEBREW_TAP_TOKEN}")
fi

# 1. Determine Target Version
VERSION="${1:-}"
if [ -z "${VERSION}" ]; then
    echo "Querying GitHub Releases API for latest release..."
    LATEST_JSON="${TMP_DIR}/latest_release.json"
    if [ ${#AUTH_HEADER[@]} -gt 0 ]; then
        curl -sSL "${AUTH_HEADER[@]}" "https://api.github.com/repos/${REPO}/releases/latest" > "${LATEST_JSON}"
    else
        curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" > "${LATEST_JSON}"
    fi

    TAG_NAME=$(grep -m 1 '"tag_name":' "${LATEST_JSON}" | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/')
    if [ -z "${TAG_NAME}" ]; then
        echo "Error: Failed to determine latest release tag from GitHub API." >&2
        cat "${LATEST_JSON}" >&2
        exit 1
    fi
    VERSION="${TAG_NAME#v}"
else
    VERSION="${VERSION#v}"
fi

echo "============================================================"
echo "Synchronizing BareStats Homebrew Tap to v${VERSION}"
echo "============================================================"

# Helper function to compute SHA-256 for a given asset URL
# Arguments: asset_name, is_optional (true/false)
get_asset_sha256() {
    local asset_name="$1"
    local is_optional="${2:-false}"
    local asset_url="https://github.com/${REPO}/releases/download/v${VERSION}/${asset_name}"
    local sha_url="${asset_url}.sha256"
    local out_file="${TMP_DIR}/${asset_name}"
    local sha=""

    # 1. Try downloading standalone .sha256 manifest first
    if curl -sSL -f "${AUTH_HEADER[@]}" "${sha_url}" -o "${TMP_DIR}/${asset_name}.sha256" 2>/dev/null; then
        sha=$(awk '{print $1}' "${TMP_DIR}/${asset_name}.sha256" | tr -d '\r\n')
    fi

    # 2. Fallback: download asset directly and compute SHA-256 locally
    if [ -z "${sha}" ] || [ ${#sha} -ne 64 ]; then
        if curl -sSL -f "${AUTH_HEADER[@]}" "${asset_url}" -o "${out_file}" 2>/dev/null; then
            if command -v sha256sum >/dev/null 2>&1; then
                sha=$(sha256sum "${out_file}" | awk '{print $1}')
            elif command -v shasum >/dev/null 2>&1; then
                sha=$(shasum -a 256 "${out_file}" | awk '{print $1}')
            fi
        fi
    fi

    if [ -n "${sha}" ] && [ ${#sha} -eq 64 ]; then
        echo "${sha}"
    else
        if [ "${is_optional}" = "true" ]; then
            echo "Warning: Asset ${asset_name} is not yet attached to release v${VERSION}. Skipping SHA-256 update." >&2
            echo ""
        else
            echo "Error: Failed to retrieve or calculate SHA-256 for required asset ${asset_name} at ${asset_url}." >&2
            exit 1
        fi
    fi
}

# 2. Extract or Compute SHA-256 Hashes
MACOS_TAR_NAME="barestats-${VERSION}-macOS.tar.gz"
LINUX_TAR_NAME="barestats-${VERSION}-linux-x86_64.tar.gz"
MACOS_DMG_NAME="barestats-${VERSION}-macOS.dmg"

# Linux is required for formula release sync (built on CI)
LINUX_TAR_SHA="${3:-}"
if [ -z "${LINUX_TAR_SHA}" ]; then
    echo "Resolving SHA-256 for Linux tarball (${LINUX_TAR_NAME})..."
    LINUX_TAR_SHA=$(get_asset_sha256 "${LINUX_TAR_NAME}" "false")
fi

# macOS assets are optional if built and uploaded subsequently from physical Mac
MACOS_TAR_SHA="${2:-}"
if [ -z "${MACOS_TAR_SHA}" ]; then
    echo "Resolving SHA-256 for macOS tarball (${MACOS_TAR_NAME})..."
    MACOS_TAR_SHA=$(get_asset_sha256 "${MACOS_TAR_NAME}" "true")
fi

MACOS_DMG_SHA="${4:-}"
if [ -z "${MACOS_DMG_SHA}" ]; then
    echo "Resolving SHA-256 for macOS DMG (${MACOS_DMG_NAME})..."
    MACOS_DMG_SHA=$(get_asset_sha256 "${MACOS_DMG_NAME}" "true")
fi

echo "Resolved Artifact Status:"
echo "  Linux Tarball: ${LINUX_TAR_SHA:-[NOT FOUND]}"
echo "  macOS Tarball: ${MACOS_TAR_SHA:-[PENDING - NOT YET ATTACHED]}"
echo "  macOS DMG:     ${MACOS_DMG_SHA:-[PENDING - NOT YET ATTACHED]}"

# 3. Update Formula and Cask Definitions
if command -v python3 >/dev/null 2>&1; then
    python3 - << EOF
import re

# Update Formula/barestats.rb
with open("${FORMULA_FILE}", "r") as f:
    formula_text = f.read()

# Update version in Formula
formula_text = re.sub(r'version "[^"]+"', f'version "${VERSION}"', formula_text, count=1)

# Update macOS SHA-256 only if asset was present
mac_tar_sha = "${MACOS_TAR_SHA}".strip()
if len(mac_tar_sha) == 64:
    def repl_macos(m):
        return re.sub(r'sha256 "[^"]+"', f'sha256 "{mac_tar_sha}"', m.group(0))
    formula_text = re.sub(r'on_macos do.*?end', repl_macos, formula_text, flags=re.DOTALL)
    print("Formula on_macos SHA-256 updated.")
else:
    print("Notice: Formula on_macos SHA-256 left unchanged (macOS tarball not yet uploaded).")

# Update Linux SHA-256
lin_tar_sha = "${LINUX_TAR_SHA}".strip()
if len(lin_tar_sha) == 64:
    def repl_linux(m):
        return re.sub(r'sha256 "[^"]+"', f'sha256 "{lin_tar_sha}"', m.group(0))
    formula_text = re.sub(r'on_linux do.*?end', repl_linux, formula_text, flags=re.DOTALL)
    print("Formula on_linux SHA-256 updated.")

with open("${FORMULA_FILE}", "w") as f:
    f.write(formula_text)

# Update Casks/barestats.rb only if macOS DMG was present
mac_dmg_sha = "${MACOS_DMG_SHA}".strip()
if len(mac_dmg_sha) == 64:
    with open("${CASK_FILE}", "r") as f:
        cask_text = f.read()
    cask_text = re.sub(r'version "[^"]+"', f'version "${VERSION}"', cask_text, count=1)
    cask_text = re.sub(r'sha256 "[^"]+"', f'sha256 "{mac_dmg_sha}"', cask_text, count=1)
    with open("${CASK_FILE}", "w") as f:
        f.write(cask_text)
    print("Cask version and SHA-256 updated.")
else:
    print("Notice: Cask left unchanged (macOS DMG not yet uploaded).")
EOF
else
    # Fallback when Python is unavailable
    if [ -n "${MACOS_DMG_SHA}" ] && [ ${#MACOS_DMG_SHA} -eq 64 ]; then
        sed -i.bak -E "s/version \"[^\"]+\"/version \"${VERSION}\"/" "${CASK_FILE}"
        sed -i.bak -E "s/sha256 \"[^\"]+\"/sha256 \"${MACOS_DMG_SHA}\"/" "${CASK_FILE}"
        rm -f "${CASK_FILE}.bak"
    fi

    awk -v ver="${VERSION}" -v mac_sha="${MACOS_TAR_SHA}" -v lin_sha="${LINUX_TAR_SHA}" '
    BEGIN { in_macos=0; in_linux=0; ver_done=0; }
    /version "[^"]+"/ && !ver_done { sub(/version "[^"]+"/, "version \"" ver "\""); ver_done=1; print; next; }
    /on_macos do/ { in_macos=1; in_linux=0; print; next; }
    /on_linux do/ { in_linux=1; in_macos=0; print; next; }
    /end/ && (in_macos || in_linux) { in_macos=0; in_linux=0; print; next; }
    in_macos && /sha256 "[^"]+"/ { if (length(mac_sha) == 64) sub(/sha256 "[^"]+"/, "sha256 \"" mac_sha "\""); print; next; }
    in_linux && /sha256 "[^"]+"/ { if (length(lin_sha) == 64) sub(/sha256 "[^"]+"/, "sha256 \"" lin_sha "\""); print; next; }
    { print }
    ' "${FORMULA_FILE}" > "${FORMULA_FILE}.tmp" && mv "${FORMULA_FILE}.tmp" "${FORMULA_FILE}"
fi

echo "============================================================"
echo "Homebrew Tap synchronization completed successfully."
echo "Formula: ${FORMULA_FILE}"
echo "Cask:    ${CASK_FILE}"
echo "============================================================"
