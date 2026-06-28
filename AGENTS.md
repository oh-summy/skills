# Working on this repository

This repo is a public, cross-agent skill library. Treat it as production-grade open-source code: everything committed here will be published and used by others.

## Git workflow

- **Never commit or push directly to `main`.** All work must happen on a feature branch.
- **Create a focused branch** for every change: `git checkout -b feat/<short-name>` or `fix/<short-name>`.
- **Open a Pull Request** for every merge. Self-merge is allowed only after the PR has been reviewed and checks pass.
- **Do not force-push, `git reset --hard`, or rebase shared history.** Use `git revert` or open a follow-up PR to undo changes.
- **Keep PRs small and focused.** One skill, one fix, or one docs update per PR is ideal.
- **Update `README.md` and `README.zh-CN.md`** when adding, removing, or renaming skills.
- **Do not run `git commit`, `git push`, `git reset`, `git rebase`, or merge PRs** unless the user has explicitly asked you to do so.

## Safety and reversibility

- **Never use `rm -rf` or any destructive deletion.** If something must be removed, move it to the system Trash/Recycle Bin or rename it with a `.bak` suffix so it can be recovered.
- **Avoid destructive git operations.** Prefer `git checkout -b`, `git revert`, or `git restore` over history-rewriting commands.
- **Never commit secrets.** This includes `.env`, API keys, tokens, passwords, and screenshots that may contain credentials. `.env` is already ignored by `.gitignore`.
- **Do not commit local agent directories** (`.claude/`, `.agents/`, `.opencode/`, `.codex/`, `.cursor/`, `.gemini/`, `.kimi/`, `.windsurf/`). They are local-only and already ignored.
- **Do not commit generated media** (`*.png`, `*.jpg`, `*.mp4`, etc.) or tool binaries (e.g. a downloaded `ffmpeg`). These are also ignored.

## Skill design standards

- Each skill lives in `skills/<skill-name>/` and must contain a `SKILL.md` file.
- Skill directory names must be kebab-case and match the `name` field in `SKILL.md` frontmatter.
- Keep the skill list flat; do not nest skill directories inside other skill directories.
- Keep skills self-contained. A user should be able to copy a single skill directory into their agent and have it work.
- Prefer POSIX-compatible shell scripts for helpers. Avoid requiring Python or heavy runtimes unless absolutely necessary.
- Include a `.env.example` only if the skill needs an API key. The real `.env` must never be committed.
- Add `references/` for templates, schemas, or docs; add `assets/` only for small, licensable bundled files.
- Keep instructions concise and actionable. Prefer small, composable skills over monolithic ones.

## Testing before PR

- Run `bash -n` on every modified `.sh` file.
- Run `./scripts/install.sh --list` and confirm the skill list is correct.
- If you change a helper script, test it with realistic arguments before marking the PR ready.
- Validate JSON files (`plugin.json`) before committing.

## Licensing and attribution

- All contributions are under the MIT license declared in `LICENSE`.
- Do not copy skill content from other repositories unless you have explicit permission and provide attribution.
- Write original examples and templates. Do not embed proprietary or copyrighted material in skills or assets.

## Communication

- Be concise in code comments and docs. Explain *why*, not just *what*.
- When in doubt, ask the user before making irreversible decisions.
