---
name: agnes-generate-video
description: Generate a video from a text prompt or an image using Agnes AI. Supports text-to-video and image-to-video via agnes-video-v2.0.
disable-model-invocation: true
---

# Agnes Generate Video

Generate videos with `agnes-video-v2.0`. Video generation is asynchronous; the script creates a task and polls until completion.

## When to use

- The user asks for a short video, animation, or cinematic clip.
- The user provides a starting image and wants it animated.

## Inputs

- `--prompt`: Text description of the desired video.
- `--image`: Optional starting image (local path or URL) for image-to-video.
- `--width`, `--height`: Output resolution. Default `1152x768`.
- `--duration`: Target duration in seconds. Default ~5 seconds.
- `--frame-rate`: FPS. Default 24.
- `--num-frames`: Override duration; must follow `8n + 1` rule and be ≤ 441.
- `--poll-interval`: Seconds between status checks. Default 10.
- `--max-wait`: Max seconds to wait. Default 1800.
- `--download`: Optional local path or directory to save the MP4. Default is `~/AgnesAI/videos/agnes_video_<timestamp>.mp4`.
- `--no-open`: Do not open the output folder after saving.

## Steps

1. Confirm the prompt, duration, and optional starting image.
2. Run the helper script in this skill directory:
   ```bash
   bash scripts/generate_video.sh --prompt "A cat walking on a beach at sunset" --duration 5
   ```
3. The script returns the video URL when the task completes.

## Example

```bash
bash scripts/generate_video.sh \
  --prompt "A cinematic drone shot over a futuristic city at dusk, neon lights, 4k quality" \
  --duration 10 \
  --download ./future_city.mp4
```

## Output location

By default the completed MP4 is downloaded to `~/AgnesAI/videos/agnes_video_<timestamp>.mp4` and the folder is opened automatically.

- macOS/Linux: `~/AgnesAI/videos/`
- Windows (Git Bash/WSL): `~/AgnesAI/videos/` resolves to your user profile folder.

Override with `--download`:

```bash
bash scripts/generate_video.sh --prompt "..." --download ./my_video.mp4
bash scripts/generate_video.sh --prompt "..." --download ./my_video_dir/
```

Skip opening the folder: add `--no-open`.

## Templates / references

- `references/templates.md` — prompt templates for cinematic text-to-video, image-to-video animation, product demos, social media shorts, keyframe transitions, etc.

## API reference

- Model: `agnes-video-v2.0`
- Docs: https://agnes-ai.com/zh-Hans/docs/agnes-video-v20

## Setup

Set `AGNES_API_KEY` as an environment variable or in a `.env` file.
