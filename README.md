# catchbin CLI

> Forward and replay webhooks from your own machine — the localhost-touching half of [catchbin](https://catchbin.io), a webhook inspector with persistence.

[**catchbin.io**](https://catchbin.io) · [Releases](https://github.com/catchbin/cli/releases)

This repository hosts the **prebuilt binary releases** of the `catchbin` command-line tool. Grab a build for your platform from the [Releases](https://github.com/catchbin/cli/releases) page.

---

## What it does

catchbin gives you a permanent webhook URL in the cloud that captures every event, so your provider (Stripe, GitHub, …) always gets a fast response — even when your laptop is closed. The CLI is the piece that runs on your machine.

### Forward webhooks to your local server

```sh
catchbin forward <endpoint-id> localhost:3000
```

Point your provider at your permanent catchbin URL once. While the CLI is connected, every captured event is forwarded to your local server and the response code and latency are shown in your terminal. Events captured while you're offline are queued and delivered in order the next time you connect. Any URL works, not just localhost:

```sh
catchbin forward <endpoint-id> https://staging.example.com
```

### Replay a captured event

```sh
catchbin replay <event-id> --target localhost:3000 [--strip | --resign]
```

- `--strip` (default) removes the provider's signature headers and replays the body byte-for-byte.
- `--resign` computes a fresh signature locally from a secret you're prompted for — it never appears in your shell history or a process listing. For CI, `--secret-from-stdin` reads it from stdin.

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

A single Go binary with no runtime dependencies — a WebSocket client, an HTTP forwarder, and terminal output. Signature verification and all webhook intelligence happen in the catchbin cloud; the only secret the CLI ever handles is the optional replay re-sign secret, entered at an interactive prompt and never written anywhere.

Learn more at [catchbin.io](https://catchbin.io).

## License

[MIT](LICENSE) © catchbin
