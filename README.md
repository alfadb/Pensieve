> [!TIP]
>
> **Don’t want to read docs? Just say `loop`.**
>
> Pensieve turns your decisions and principles into reusable execution context.

<div align="center">

# Pensieve

**Store your decisions and principles. Claude reads them to make better choices.**

[![GitHub Stars](https://img.shields.io/github/stars/kingkongshot/Pensieve?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/kingkongshot/Pensieve/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[Chinese README](https://github.com/kingkongshot/Pensieve/blob/zh/README.md)

</div>

## What It Is

Pensieve is a Claude Code plugin focused on execution quality:

- `loop`: break down and complete complex work with auto-continue
- memory: keep maxims, decisions, knowledge, and pipelines in project scope
- self-improve: continuously refine behavior and workflows

This README is intentionally short.

## For Humans

Use these docs as entry points:

- Installation: [`docs/installation.md`](docs/installation.md)
- Updates: [`docs/update.md`](docs/update.md)
- Data migration from old layouts: run `/upgrade` (tool source: [`skills/pensieve/tools/upgrade/_upgrade.md`](skills/pensieve/tools/upgrade/_upgrade.md))

If you only remember one command, use `loop`.

## For LLM Agents

Treat docs as the source of truth and execute from there:

1. Install and initialize by following [`docs/installation.md`](docs/installation.md)
2. Update using [`docs/update.md`](docs/update.md)
3. Migrate old user data and clean old plugin naming via [`skills/pensieve/tools/upgrade/_upgrade.md`](skills/pensieve/tools/upgrade/_upgrade.md)

Do not duplicate long installation or upgrade procedures inside this README.

## Core Commands

- `/loop`
- `/pipeline`
- `/selfimprove`
- `/upgrade`

## License

MIT. See [`LICENSE`](LICENSE).
