# catchbin CLI

> **catchbin is discontinued.** The project stopped on 2026-10-31 without launching. This repository is archived and kept for reference only. It is not maintained, and the `catchbin.io` service does not exist.

> Forward webhooks to your own machine — the localhost-touching half of catchbin, a webhook inspector with persistence.

[Releases](https://github.com/catchbin/cli/releases)

This repository hosts the **prebuilt binary releases** of the `catchbin` command-line tool. Grab a build for your platform from the [Releases](https://github.com/catchbin/cli/releases) page.

---

## What it does

catchbin gives you a permanent webhook URL in the cloud that captures every event, so your provider (Stripe, GitHub, …) always gets a fast response — even when your laptop is closed. The CLI is the piece that runs on your machine: it forwards those captured webhooks to your local server in real time.

```sh
# 1. authenticate once (stores your workspace API key)
catchbin configure

# 2. forward captured events to your local server
catchbin forward <workspace-id>/<slug> localhost:3000
```

Point your provider at your permanent catchbin URL once. While the CLI is connected, every captured event is forwarded to your local server and the response code and latency are shown in your terminal. Events captured while you're offline are queued and delivered in order the next time you connect.

Any target URL works, not just localhost:

```sh
catchbin forward abc123/my-endpoint https://staging.example.com
```

The API key can also come from the `CATCHBIN_API_KEY` environment variable instead of `catchbin configure`.

---

## Installation

The Homebrew tap and the `curl | sh` installer are retired. The archives from the final release remain on the releases page.

### Direct download

Prebuilt archives for macOS, Linux, and Windows are on the [releases page](https://github.com/catchbin/cli/releases). Windows: download the `.zip`, extract `catchbin.exe`, and put it on your `PATH`.

## Verifying a release

Each release's checksum manifest (`checksums.txt`) is signed with [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) keyless signing; verification needs only public inputs. For release `vX.Y.Z` (replace with the tag you downloaded):

```sh
# 1. Verify the checksum manifest was signed by catchbin's release workflow
cosign verify-blob checksums.txt \
  --signature checksums.txt.sig \
  --certificate checksums.txt.pem \
  --certificate-identity "https://github.com/catchbin/catchbin-cli/.github/workflows/release.yml@refs/tags/vX.Y.Z" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

# 2. Verify your downloaded archive against the verified manifest
sha256sum --check --ignore-missing checksums.txt   # macOS: shasum -a 256 -c --ignore-missing checksums.txt
```

Step 1 prints `Verified OK`; step 2 reports `OK` for your archive. The tag in `--certificate-identity` must match the release you are verifying. Verification fails if the manifest or an archive was tampered with, or if the signing identity or issuer differs.

> The CLI checks for newer releases and lets you know when one is available. It is **informational only** — catchbin never auto-updates itself.

---

## About

A single Go binary with no runtime dependencies — a WebSocket client, an HTTP forwarder, and terminal output. Signature verification and all webhook intelligence happen in the catchbin cloud.

## License

[MIT](LICENSE) © catchbin
