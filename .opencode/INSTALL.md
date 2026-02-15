# Installing Pensieve for OpenCode

This repository is primarily a Claude Code plugin. The OpenCode integration is implemented as:

- OpenCode plugin: `.opencode/plugins/pensieve.js`
- Pensieve system skills: `skills/pensieve/`

## Prerequisites

- OpenCode.ai installed
- Git installed

## Installation (Global)

1) Clone (or use as a submodule) into your OpenCode config dir:

```bash
git clone git@github.com:alfadb/Pensieve.git ~/.config/opencode/Pensieve
```

2) Register the OpenCode plugin

OpenCode's official docs use `plugins/` (plural). Some setups also accept `plugin/` (singular).

```bash
mkdir -p ~/.config/opencode/plugins
rm -f ~/.config/opencode/plugins/pensieve.js
ln -s ~/.config/opencode/Pensieve/.opencode/plugins/pensieve.js ~/.config/opencode/plugins/pensieve.js
```

3) (Optional) Make the `pensieve` skill discoverable

If your OpenCode skill discovery uses `skills/` (plural):

```bash
mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/pensieve
ln -s ~/.config/opencode/Pensieve/skills/pensieve ~/.config/opencode/skills/pensieve
```

If your OpenCode skill discovery uses `skill/` (singular):

```bash
mkdir -p ~/.config/opencode/skill
rm -rf ~/.config/opencode/skill/pensieve
ln -s ~/.config/opencode/Pensieve/skills/pensieve ~/.config/opencode/skill/pensieve
```

4) Restart OpenCode

Restart OpenCode so the plugin is loaded.

## Verify

- Start a new session.
- Confirm the system prompt contains a `<PENSIEVE>` block.
