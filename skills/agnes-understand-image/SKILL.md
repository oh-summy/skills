---
name: agnes-understand-image
description: Analyze an image with Agnes AI and return structured information. Supports public image URLs, local image files, and JSON output.
disable-model-invocation: true
---

# Agnes Understand Image

Analyze an image with `agnes-2.0-flash` and return a structured understanding.

## When to use

- The user asks "what is in this image", "describe this screenshot", or "extract text/structure from this image".
- The user provides an image file path or URL and wants a concise or JSON-formatted analysis.

## Inputs

- `--image`: Path to a local image file or a publicly accessible image URL.
- `--prompt`: The analysis instruction, e.g. "Describe this image in one sentence" or "Extract all text as JSON".
- `--format`: `text`, `structured` (default), or `json`.
- `--json`: Alias for `--format json`.
- `--model`: Optional model override. Default is `agnes-2.0-flash`.

## Steps

1. Confirm the image source with the user if it is not already provided.
2. Run the helper script in this skill directory:
   ```bash
   bash scripts/understand_image.sh --image <path-or-url> --prompt "<instruction>"
   ```
3. Return the model output to the user. If `--json` was used, validate that the output is valid JSON before presenting it.

## Example

```bash
bash scripts/understand_image.sh \
  --image ./screenshot.png \
  --prompt "List the UI elements and their likely purpose as JSON" \
  --json
```

## Output format

By default the model returns a structured analysis including:

- Summary
- Description
- Subjects
- Style
- Color palette
- Composition
- Mood
- Text in image
- Metadata (dimensions, aspect ratio, format)

Use `--format json` to get machine-readable JSON. See `references/output-schema.md` for the full schema.

## Templates / references

- `references/output-schema.md` — structured output schema

## API reference

- Model: `agnes-2.0-flash`
- Docs: https://agnes-ai.com/zh-Hans/docs/agnes-20-flash

## Setup

Set your Agnes API key:

```bash
export AGNES_API_KEY=your_key_here
```

Or create a `.env` file from the repository root `.env.example`.
