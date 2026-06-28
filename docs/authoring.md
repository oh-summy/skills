# Authoring a skill

## File layout

```
skills/<skill-name>/
├── SKILL.md          # required
├── scripts/          # optional helper scripts
├── references/       # optional reference docs
└── assets/           # optional templates, images, etc.
```

## Frontmatter

```yaml
---
name: <skill-name>
description: <one-line summary>
---
```

- `name` — unique, kebab-case, must match the directory name.
- `description` —
  - For **model-invoked** skills: write it for the model, e.g. "Use when the user asks to ...".
  - For **user-invoked** skills: write it for a human reader and add `disable-model-invocation: true`.

## User-invoked vs model-invoked

| Type | Frontmatter | Invoked by |
| ---- | ----------- | ---------- |
| User-invoked | `disable-model-invocation: true` | Human typing `/skill-name` |
| Model-invoked | omit the flag | Model auto-detection or human mention |

A user-invoked skill may invoke model-invoked skills, but never another user-invoked skill.

## Body

- State the goal in one sentence.
- Provide clear, numbered steps.
- Reference bundled files with relative paths (`scripts/helper.sh`, `assets/template.json`).
- Keep one skill per responsibility. If a workflow has distinct phases, split it.

## Validation checklist

- [ ] Directory name matches `name` in frontmatter.
- [ ] `SKILL.md` exists and has valid YAML frontmatter.
- [ ] `README.md` lists the skill.
- [ ] The installer can see it: `./scripts/install.sh --list`.
