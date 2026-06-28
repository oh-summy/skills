# oh-summy/skills

一套跨 agent 的 skill 集合，兼容 [Claude Code](https://claude.ai/code)、[OpenCode](https://opencode.ai)、[Codex](https://github.com/openai/codex)、[Kimi Code](https://github.com/MoonshotAI/kimi-cli)、Cursor、Gemini CLI，以及所有支持开放 `SKILL.md` 标准的 AI 编程助手。

> 目标：维护一套“小而可组合”的 agent skills，既支持一键安装全部，也支持只安装某一个。

目前已包含 [Agnes AI](https://agnes-ai.com) 多模态 skill（图片/视频理解、图片/视频生成），未来会持续补充更多公开或自用的 skill。

**语言：** [English](./README.md) | [简体中文](./README.zh-CN.md)

## 快速开始

### 一键安装全部 skills

```bash
npx skills add oh-summy/skills
```

全局安装，让所有项目都能使用：

```bash
npx skills add oh-summy/skills -g -y
```

### 只安装某一个 skill

```bash
npx skills add oh-summy/skills --skill agnes-understand-image -a claude-code
```

或者使用本仓库自带的安装脚本：

```bash
# 全局安装某个 skill 到所有支持的 agent
./scripts/install.sh agnes-understand-image

# 安装到当前项目的 agent 目录
./scripts/install.sh agnes-understand-image --project

# 列出所有可用 skills
./scripts/install.sh --list
```

## 配置

1. 复制 `.env.example` 为 `.env`，并填入你的 Agnes AI API Key（在 [platform.agnes-ai.com](https://platform.agnes-ai.com/settings/apiKeys) 获取）：
   ```bash
   cp .env.example .env
   # 编辑 .env
   ```
2. 或直接导出：
   ```bash
   export AGNES_API_KEY=your_key_here
   ```

> 不要把 `.env` 提交到仓库，`.gitignore` 已忽略它。

Agnes AI 相关 skill 需要 `curl` 和 `jq`。`agnes-understand-video` 还需要 `ffmpeg`/`ffprobe`。

## 仓库结构

- `scripts/` — 全局安装脚本（`install.sh`、`list-skills.sh`），用于把 skill 安装到各个 agent。
- `skills/<name>/` — 每个 skill 自包含，有自己的 `SKILL.md` 和辅助脚本。
  - `skills/<name>/scripts/` — skill 自己的辅助脚本。
  - `skills/<name>/references/` — 该 skill 的模板、输出范式、参考文档。
  - `skills/<name>/assets/` — 可选的模板文件、示例资源。

## 支持的 agent

| Agent       | 全局 skill 路径                     | 项目级 skill 路径      |
| ----------- | ---------------------------------- | --------------------- |
| Claude Code | `~/.claude/skills/<name>/`         | `.claude/skills/`     |
| Kimi Code   | `~/.agents/skills/<name>/`         | `.agents/skills/`     |
| OpenCode    | `~/.config/opencode/skills/<name>/`| `.opencode/skills/`   |
| Codex CLI   | `~/.codex/skills/<name>/`          | `.codex/skills/`      |
| Cursor      | `~/.cursor/skills/<name>/`         | `.cursor/skills/`     |
| Gemini CLI  | `~/.gemini/skills/<name>/`         | `.gemini/skills/`     |

> 本仓库采用扁平结构 `skills/<name>/SKILL.md`，这样即使不支持递归扫描嵌套目录的 agent（如 Kimi Code）也能正常加载。

## Skills 列表

### Agnes AI

由 [Agnes AI](https://agnes-ai.com) 提供的多模态 skill。目前有免费额度可用。

- [`agnes-understand-image`](./skills/agnes-understand-image/SKILL.md) — 分析图片并返回结构化信息。
- [`agnes-generate-image`](./skills/agnes-generate-image/SKILL.md) — 根据提示词生成或编辑图片。
- [`agnes-understand-video`](./skills/agnes-understand-video/SKILL.md) — 抽取视频帧并进行描述。
- [`agnes-generate-video`](./skills/agnes-generate-video/SKILL.md) — 根据提示词或图片生成视频。

## 手动安装

把任意 skill 目录复制到你的 agent skill 路径即可，例如：

```bash
# Claude Code
cp -r skills/agnes-understand-image ~/.claude/skills/

# Kimi Code / 通用路径
cp -r skills/agnes-understand-image ~/.agents/skills/
```

复制后重启 agent 即可生效。

## 编写新的 skill

请参考 [`docs/authoring.md`](./docs/authoring.md)。

## 许可证

MIT © [oh-summy](https://github.com/oh-summy)
