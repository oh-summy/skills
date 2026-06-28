---
name: agnes-generate-image
description: Generate or edit an image with Agnes AI. Supports text-to-image and image-to-image via agnes-image-2.1-flash.
disable-model-invocation: true
---

# Agnes Generate Image

Generate or edit images with `agnes-image-2.1-flash`.

## When to use

- The user asks for an image, icon, banner, mockup, product photo, or edited image.
- The user provides a reference image and wants a variation or edit.

## Inputs

- `--prompt`: Text description of the desired image.
- `--size`: Output size, e.g. `1024x768`, `1024x1024`, `768x1024`. Default `1024x768`.
- `--image`: Optional reference image (local path or URL) for image-to-image.
- `--response-format`: `base64` (default) or `url`. Base64 mode saves images locally.
- `--n`: Number of images. Default 1.
- `--output-dir`: Directory for saved images. Default is `~/AgnesAI/images`.
- `--no-open`: Do not open the output folder after saving.
- `--model`: Optional model override. Default is `agnes-image-2.1-flash`.

## Steps

1. Confirm the prompt and optional reference image.
2. Run the helper script in this skill directory:
   ```bash
   bash scripts/generate_image.sh --prompt "a cat in space" --size 1024x1024
   ```
3. Return the generated image URL(s) or saved file paths to the user.

## Example

```bash
bash scripts/generate_image.sh \
  --prompt "A minimalist logo of a rocket, vector style, blue gradient" \
  --size 1024x1024 \
  --response-format url
```

## Output location

By default (`--response-format base64`) the generated image is saved to `--output-dir` and the folder is opened automatically.

- Default: `~/AgnesAI/images` on macOS/Linux, or `%USERPROFILE%\AgnesAI\images` when running under Git Bash on Windows.
- Custom: `bash scripts/generate_image.sh --output-dir ./my_images ...`
- Skip opening the folder: add `--no-open`.
- URL-only mode: `--response-format url` returns a public URL without saving locally.

## Templates / references

- `references/templates.md` — prompt templates for creative design, marketing, social media, product shots, style transfer, thumbnails/banners, etc.

## API reference

- Model: `agnes-image-2.1-flash`
- Docs: https://agnes-ai.com/zh-Hans/docs/agnes-image-21-flash

## Setup

Set `AGNES_API_KEY` as an environment variable or in a `.env` file.
