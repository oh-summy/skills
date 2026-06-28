# oh-summy/skills

Cross-agent skills for [Claude Code](https://claude.ai/code), [OpenCode](https://opencode.ai), [Codex](https://github.com/openai/codex), [Kimi Code](https://github.com/MoonshotAI/kimi-cli), Cursor, Gemini CLI, and any other agent that supports the open `SKILL.md` standard.

> Goal: a small, composable skill library that can be installed in one click, while still letting users grab just the skill they need.

Currently includes [Agnes AI](https://agnes-ai.com) multimodal skills for image and video workflows. More skills will be added over time.

**Languages:** [English](./README.md) | [简体中文](./README.zh-CN.md)

## Quick start

### Install all skills (one-click)

```bash
npx skills add oh-summy/skills
```

Install globally so they are available in every project:

```bash
npx skills add oh-summy/skills -g -y
```

### Install a single skill

```bash
npx skills add oh-summy/skills --skill agnes-understand-image -a claude-code
```

Or use the bundled installer (run without options for an interactive prompt):

```bash
# interactive menu
./scripts/install.sh

# install for a specific agent (direct install into ~/.claude/skills/)
./scripts/install.sh --agent claude agnes-understand-image

# install for multiple agents (~/.agents/skills/ becomes canonical, others symlink)
./scripts/install.sh --agent claude --agent codex --agent opencode

# install for all supported agents
./scripts/install.sh --agent all

# install into the cross-runtime ~/.agents/skills/ directory only
./scripts/install.sh --universal

# list available skills
./scripts/install.sh --list
```

## Setup

1. Copy `.env.example` to `.env` and add your Agnes AI API key (get it at [platform.agnes-ai.com](https://platform.agnes-ai.com/settings/apiKeys)):
   ```bash
   cp .env.example .env
   # edit .env
   ```
2. Or export the key directly:
   ```bash
   export AGNES_API_KEY=your_key_here
   ```

> Never commit `.env`. It is already ignored by `.gitignore`.

The Agnes AI skills require `curl` and `jq`. `agnes-understand-video` also requires `ffmpeg`/`ffprobe`.

## Repository layout

- `scripts/` — global installer for the whole skill library (`install.sh`, `list-skills.sh`).
- `skills/<name>/` — each skill is self-contained with its own `SKILL.md` and helper scripts.
  - `skills/<name>/scripts/` — the helper scripts that the skill uses.
  - `skills/<name>/references/` — templates, schemas, and docs for that skill.
  - `skills/<name>/assets/` — optional bundled assets (templates, examples).

## Supported agents

| Agent       | Global skill path                  | Project skill path     |
| ----------- | ---------------------------------- | ---------------------- |
| Claude Code | `~/.claude/skills/<name>/`         | `.claude/skills/`      |
| Kimi Code   | `~/.agents/skills/<name>/`         | `.agents/skills/`      |
| OpenCode    | `~/.config/opencode/skills/<name>/`| `.opencode/skills/`    |
| Codex CLI   | `~/.codex/skills/<name>/`          | `.codex/skills/`       |
| Cursor      | `~/.cursor/skills/<name>/`         | `.cursor/skills/`      |
| Gemini CLI  | `~/.gemini/skills/<name>/`         | `.gemini/skills/`      |

> This repo keeps skills flat (`skills/<name>/SKILL.md`) so every agent — including those that do not recurse nested directories — can load them.

## Skills

### Agnes AI

Multimodal skills powered by [Agnes AI](https://agnes-ai.com). A free tier is available.

- [`agnes-understand-image`](./skills/agnes-understand-image/SKILL.md) — Analyze an image and return structured information.
- [`agnes-generate-image`](./skills/agnes-generate-image/SKILL.md) — Generate or edit an image from a prompt.
- [`agnes-understand-video`](./skills/agnes-understand-video/SKILL.md) — Sample frames from a video and describe them.
- [`agnes-generate-video`](./skills/agnes-generate-video/SKILL.md) — Generate a video from a prompt or an image.

## Manual install

Copy any skill directory into your agent's skill path, for example:

```bash
# Claude Code
cp -r skills/agnes-understand-image ~/.claude/skills/

# Kimi Code / universal
cp -r skills/agnes-understand-image ~/.agents/skills/
```

Then restart your agent.

## Writing a new skill

See [`docs/authoring.md`](./docs/authoring.md).

## License

MIT © [oh-summy](https://github.com/oh-summy)
