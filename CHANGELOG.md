# Changelog

All notable user-facing changes to the `catchbin` CLI.

Entries describe what you can do differently after upgrading. Internal refactors,
dependency bumps, and build changes are omitted unless they change behaviour you can
observe. A release that changes nothing for users says so.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The CLI major
tracks the public API major (`/v1` ↔ `1.x`).

Releases before `0.1.4` predate this file and are not recorded here.

## [Unreleased]

No user-facing changes.

The API client was regenerated against the current public contract, which added two
optional response fields and an error-reply type. No command surfaces them yet, so
nothing you run behaves differently.
