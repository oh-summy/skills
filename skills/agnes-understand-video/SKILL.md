---
name: agnes-understand-video
description: Analyze a video with Agnes AI by sampling frames and return structured information. Requires ffmpeg and ffprobe.
disable-model-invocation: true
---

# Agnes Understand Video

Understand a local video by sampling frames and analyzing them with `agnes-2.0-flash`.

## When to use

- The user asks "what happens in this video", "summarize this video", or "extract key events from this clip".
- A local video file path or publicly accessible video URL is available.

## Inputs

- `--video`: Path to a local video file or a publicly accessible video URL.
- `--prompt`: Analysis instruction.
- `--timestamp`: Analyze around a specific timestamp, e.g. `30`, `30.5`, `00:00:30`, `0:30`.
- `--window`: Seconds around `--timestamp` to sample. Default 2.
- `--frames`: Number of frames to sample. Default 5.
- `--format`: `text`, `structured` (default), or `json`.
- `--json`: Alias for `--format json`.
- `--max-width`: Resize frames to this width to save tokens. Default 512.
- `--model`: Optional model override. Default is `agnes-2.0-flash`.

## Steps

1. Confirm the video source and what the user wants to know.
2. Run the helper script in this skill directory:
   ```bash
   bash scripts/understand_video.sh --video ./clip.mp4 --prompt "Summarize the main events in this video"
   ```
3. The script downloads the video if needed, extracts frames, sends them to `agnes-2.0-flash`, and returns the analysis.

## Examples

Analyze the whole video:

```bash
bash scripts/understand_video.sh \
  --video ./demo.mp4 \
  --prompt "Describe the setting, characters, and actions in JSON format" \
  --json
```

Analyze what happens around the 30-second mark:

```bash
bash scripts/understand_video.sh \
  --video ./demo.mp4 \
  --timestamp 30 \
  --window 2 \
  --prompt "What happens around the 30-second mark?"
```

## Output format

By default the model returns a structured analysis including:

- Summary
- Keyframes analyzed (with timestamps)
- Scene-by-scene description
- Settings
- Characters / actions
- Camera movement
- Visual style
- Mood / tone
- Audio description
- Metadata (duration, resolution, frame rate, format)

The script also prints the extracted keyframe timestamps so you know exactly which moments were analyzed.

Use `--format json` to get machine-readable JSON. See `references/output-schema.md` for the full schema.

## Templates / references

- `references/output-schema.md` — structured output schema

## API reference

- Model: `agnes-2.0-flash`
- Docs: https://agnes-ai.com/zh-Hans/docs/agnes-20-flash

## Requirements

- `bash`, `curl`, `jq`, `ffmpeg`, `ffprobe`
- `AGNES_API_KEY` set or `.env` configured
