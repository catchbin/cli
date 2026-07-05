#!/bin/sh
# catchbin installer — https://catchbin.io
#
# Usage:
#   curl -fsSL https://catchbin.io/install.sh | sh
#   sh install.sh
#
# Detects your OS/arch, downloads the matching release archive from the public
# catchbin/cli repo, verifies its SHA-256 against the release checksum manifest,
# and installs the `catchbin` binary to /usr/local/bin (falling back to
# ~/.local/bin when that is not writable). It never uses sudo and handles no
# secrets. All progress and diagnostics go to stderr; stdout is left silent.
#
# POSIX sh only — no bashisms. Runs under dash, BusyBox ash, and macOS /bin/sh.

set -eu

# The public releases repo. Both the archives and checksums.txt live under its
# GitHub Releases; this is the same public feed the CLI's update notifier polls.
REPO="catchbin/cli"
RELEASES_PAGE="https://github.com/${REPO}/releases"
API_LATEST="https://api.github.com/repos/${REPO}/releases/latest"

# ---------------------------------------------------------------------------
# Output helpers — everything to stderr; stdout stays reserved/silent.
# ---------------------------------------------------------------------------
log() { printf '%s\n' "$*" >&2; }
err() { printf 'error: %s\n' "$*" >&2; }

# Populated once a temp workdir exists; cleaned by the EXIT trap on every path.
WORKDIR=""
cleanup() {
	if [ -n "${WORKDIR}" ] && [ -d "${WORKDIR}" ]; then
		rm -rf "${WORKDIR}"
	fi
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# 1. Prerequisites — checked before any download; abort naming what is missing.
# ---------------------------------------------------------------------------
need() {
	if ! command -v "$1" >/dev/null 2>&1; then
		err "required tool not found: $1 (please install it and re-run)"
		exit 1
	fi
}
need curl
need tar
need uname
need mktemp

# One of sha256sum (Linux) or shasum (macOS) is required for verification.
SHA_TOOL=""
if command -v sha256sum >/dev/null 2>&1; then
	SHA_TOOL="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
	SHA_TOOL="shasum"
else
	err "need sha256sum or shasum to verify the download; neither was found"
	exit 1
fi

# ---------------------------------------------------------------------------
# 2. Platform detection → os in {darwin,linux}, arch in {amd64,arm64}.
# ---------------------------------------------------------------------------
os_raw="$(uname -s)"
arch_raw="$(uname -m)"

case "${os_raw}" in
	Darwin) OS="darwin" ;;
	Linux) OS="linux" ;;
	*)
		err "unsupported operating system: ${os_raw}"
		log "catchbin ships macOS, Linux, and Windows builds — see ${RELEASES_PAGE}"
		exit 1
		;;
esac

case "${arch_raw}" in
	x86_64 | amd64) ARCH="amd64" ;;
	arm64 | aarch64) ARCH="arm64" ;;
	*)
		err "unsupported architecture: ${arch_raw}"
		log "prebuilt archives are available at ${RELEASES_PAGE}"
		exit 1
		;;
esac

# ---------------------------------------------------------------------------
# 3. Resolve the latest release tag (vX.Y.Z) from the public GitHub API.
# ---------------------------------------------------------------------------
log "Resolving the latest catchbin release..."
api_json="$(curl -fsSL "${API_LATEST}" 2>/dev/null)" || {
	err "could not reach the GitHub release API (network issue or rate limit)"
	log "try again shortly, or download manually from ${RELEASES_PAGE}"
	exit 1
}

# Extract "tag_name":"vX.Y.Z" without jq. Grep the field, strip to the value.
TAG="$(printf '%s' "${api_json}" | grep -o '"tag_name"[ ]*:[ ]*"[^"]*"' | head -n 1 | sed 's/.*"tag_name"[ ]*:[ ]*"\([^"]*\)".*/\1/')"
if [ -z "${TAG}" ]; then
	err "could not determine the latest release tag from the GitHub API response"
	log "download manually from ${RELEASES_PAGE}"
	exit 1
fi

# goreleaser strips the leading v from archive names (catchbin_X.Y.Z_os_arch).
VERSION="${TAG#v}"
ASSET="catchbin_${VERSION}_${OS}_${ARCH}.tar.gz"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

# ---------------------------------------------------------------------------
# 4. Download the archive + checksum manifest into a trap-cleaned workdir.
# ---------------------------------------------------------------------------
WORKDIR="$(mktemp -d)"
log "Downloading ${ASSET} (${TAG})..."
if ! curl -fsSL -o "${WORKDIR}/${ASSET}" "${BASE_URL}/${ASSET}"; then
	err "failed to download ${ASSET}"
	log "no build for ${OS}/${ARCH} in ${TAG}? see ${RELEASES_PAGE}"
	exit 1
fi
if ! curl -fsSL -o "${WORKDIR}/checksums.txt" "${BASE_URL}/checksums.txt"; then
	err "failed to download the checksum manifest for ${TAG}"
	exit 1
fi

# ---------------------------------------------------------------------------
# 5. Verify the archive against the signed checksum manifest BEFORE installing.
#    Any mismatch aborts with nothing installed (no partial state).
# ---------------------------------------------------------------------------
log "Verifying checksum..."
expected="$(grep " ${ASSET}\$" "${WORKDIR}/checksums.txt" | head -n 1 | cut -d' ' -f1)"
if [ -z "${expected}" ]; then
	err "no checksum entry for ${ASSET} in the manifest — refusing to install"
	exit 1
fi
if [ "${SHA_TOOL}" = "sha256sum" ]; then
	actual="$(sha256sum "${WORKDIR}/${ASSET}" | cut -d' ' -f1)"
else
	actual="$(shasum -a 256 "${WORKDIR}/${ASSET}" | cut -d' ' -f1)"
fi
if [ "${expected}" != "${actual}" ]; then
	err "checksum mismatch for ${ASSET} — download may be corrupt or tampered; nothing installed"
	exit 1
fi

# ---------------------------------------------------------------------------
# 6. Extract and install. /usr/local/bin when writable, else ~/.local/bin.
#    Atomic replace: copy to a temp name in the destination dir, then mv.
# ---------------------------------------------------------------------------
log "Extracting..."
if ! tar -xzf "${WORKDIR}/${ASSET}" -C "${WORKDIR}" catchbin; then
	err "could not extract the catchbin binary from ${ASSET}"
	exit 1
fi
chmod 0755 "${WORKDIR}/catchbin"

# Choose an install directory we can actually write to — never escalate.
DEST=""
if [ -w /usr/local/bin ] || { [ ! -e /usr/local/bin ] && mkdir -p /usr/local/bin 2>/dev/null; }; then
	if [ -w /usr/local/bin ]; then
		DEST="/usr/local/bin"
	fi
fi
if [ -z "${DEST}" ]; then
	# Fall back to the per-user bin; create it if absent.
	user_bin="${HOME}/.local/bin"
	if mkdir -p "${user_bin}" 2>/dev/null && [ -w "${user_bin}" ]; then
		DEST="${user_bin}"
	fi
fi
if [ -z "${DEST}" ]; then
	err "no writable install directory (/usr/local/bin and ~/.local/bin both unavailable)"
	log "re-run with a writable prefix, or copy ${WORKDIR}/catchbin somewhere on your PATH yourself"
	log "(this installer never uses sudo)"
	exit 1
fi

# Atomic install: land next to the target on the same filesystem, then mv.
tmp_bin="${DEST}/.catchbin.install.$$"
if ! cp "${WORKDIR}/catchbin" "${tmp_bin}" || ! mv -f "${tmp_bin}" "${DEST}/catchbin"; then
	rm -f "${tmp_bin}" 2>/dev/null || true
	err "failed to install catchbin into ${DEST}"
	exit 1
fi

# ---------------------------------------------------------------------------
# 7. Report success. Warn if the chosen dir is not on PATH.
# ---------------------------------------------------------------------------
log "Installed catchbin ${TAG} to ${DEST}/catchbin"
case ":${PATH}:" in
	*":${DEST}:"*) ;;
	*)
		log ""
		log "${DEST} is not on your PATH. Add it, e.g.:"
		log "    export PATH=\"${DEST}:\$PATH\""
		;;
esac
log "Run 'catchbin --version' to verify."
