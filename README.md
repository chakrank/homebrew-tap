# Homebrew Tap (`chakrank/tap`)

[![Homebrew](https://img.shields.io/badge/Homebrew-Tap-FBB040?logo=homebrew&logoColor=white)](https://brew.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Official [Homebrew](https://brew.sh) tap providing pre-compiled binaries, CLI formulae, and macOS application bundles for open-source projects by [@chakrank](https://github.com/chakrank) across **macOS** (Apple Silicon & Intel) and **Linux**.

---

## Quick Start

Add this tap once to install any package by name:

```bash
brew tap chakrank/tap

```

Or install any package directly with a single command without tapping first:

```bash
# Install a CLI / Linux / macOS Formula
brew install chakrank/tap/<package>

# Install a macOS GUI Application Cask
brew install --cask chakrank/tap/<package>

```

---

## Available Packages

### Casks (macOS Native GUI Applications)

| Package                                                | Description                                                                                                    | Install Command                              |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| **[BareStats](https://github.com/chakrank/BareStats)** | Ultra-lightweight, near-zero-overhead native system & AI telemetry overlay (`BareStats.app` + `barestats` CLI) | `brew install --cask chakrank/tap/barestats` |

### Formulae (macOS & Linux Binaries / CLI Tools)

| Package                                                | Platforms    | Description                                                                  | Install Command                       |
| ------------------------------------------------------ | ------------ | ---------------------------------------------------------------------------- | ------------------------------------- |
| **[BareStats](https://github.com/chakrank/BareStats)** | Linux, macOS | Standalone native telemetry overlay, headless cluster satellite daemon & CLI | `brew install chakrank/tap/barestats` |

---

## Package Reference

**1. macOS Desktop App + CLI (Cask)**
Installs `BareStats.app` into `/Applications` and links the `barestats` CLI binary into your `PATH`:

```bash
brew install --cask chakrank/tap/barestats

# Launch GUI overlay
open -a BareStats

# Control via CLI
barestats --toggle
barestats --move
barestats --preset TopRight

```

**2. Linux & macOS Standalone Binary (Formula)**
Installs the native `barestats` binary and desktop integrations on Linux (or macOS without the `.app` bundle):

```bash
brew install chakrank/tap/barestats

# Run overlay or hardware verification
barestats
barestats --test
barestats --help

```

---

## Updating Packages

Update Homebrew metadata and upgrade installed packages to their latest release:

```bash
# Fetch latest tap metadata
brew update

# Upgrade all installed packages
brew upgrade

# Or upgrade a specific Formula / Cask
brew upgrade <package>
brew upgrade --cask <package>

```

---

## Uninstalling Packages

Remove an installed package from your system:

```bash
# Uninstall a Formula
brew uninstall <package>

# Uninstall a macOS Cask (and optionally remove user config/logs)
brew uninstall --cask <package>
brew zap <package>

# Remove this tap completely
brew untap chakrank/tap

```

---

## Repository Structure & Maintainer Guide

```text
homebrew-tap/
├── Casks/       # macOS GUI application bundles (.dmg / .app)
├── Formula/     # Cross-platform macOS & Linux CLI / binary packages
└── scripts/     # Automated GitHub Release SHA-256 & version sync helpers

```

Formulae and Casks in this repository are automatically synchronized with upstream GitHub Releases via GitHub Actions CI. To trigger a manual release sync locally:

```bash
chmod +x scripts/sync_release_from_github.sh
./scripts/sync_release_from_github.sh [VERSION]

```

---

## License

This tap repository and its package definitions are released under the [MIT License](LICENSE). Individual packages are governed by their respective upstream licenses.
