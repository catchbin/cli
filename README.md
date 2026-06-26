# catchbin CLI

> Forward webhooks to your own machine — the localhost-touching half of [catchbin](https://catchbin.io), a webhook inspector with persistence.

[**catchbin.io**](https://catchbin.io) · [Releases](https://github.com/catchbin/cli/releases)

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

## Install

Prebuilt binaries for **macOS, Linux, and Windows** (amd64 and arm64) are published on the [Releases](https://github.com/catchbin/cli/releases) page.

### Manual download

1. Download the archive for your platform from the [latest release](https://github.com/catchbin/cli/releases/latest) (e.g. `catchbin_<version>_linux_amd64.tar.gz`).
2. Extract it and move the `catchbin` binary onto your `PATH`:

```sh
tar xzf catchbin_*_linux_amd64.tar.gz
install -m 0755 catchbin /usr/local/bin/catchbin   # or any directory on your PATH
catchbin --help
```

Each release ships a `checksums.txt` so you can verify your download:

```sh
sha256sum -c checksums.txt --ignore-missing
```

### Homebrew and `curl | sh` — planned

```sh
brew install catchbin/tap/catchbin               # coming soon
curl -fsSL https://catchbin.io/install.sh | sh   # coming soon
```

> The CLI checks for newer releases and lets you know when one is available. It is **informational only** — catchbin never auto-updates itself.

---

## About

A single Go binary with no runtime dependencies — a WebSocket client, an HTTP forwarder, and terminal output. Signature verification and all webhook intelligence happen in the catchbin cloud.

Learn more at [catchbin.io](https://catchbin.io).

## License

[MIT](LICENSE) © catchbin
