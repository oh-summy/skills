# Agnes Understand Video — Output Schema

When analyzing a video, return structured information in this format.

## Text format

```markdown
## Summary
One-sentence overview.

## Keyframes analyzed
- 00:00:28.000: what is visible
- 00:00:29.000: what is visible
- 00:00:30.000: what is visible

## Scene-by-scene description
- 00:00 - 00:05: what happens
- 00:05 - 00:10: what happens

## Settings
Locations, environments, time of day.

## Characters / actions
Who or what appears and what they do.

## Camera movement
Pan, zoom, static, handheld, drone, etc.

## Visual style
Color grading, lighting, cinematic style.

## Mood / tone
Atmosphere or emotional impression.

## Audio description
Music, dialogue, sound effects (if inferable).

## Metadata
- Duration: [seconds]
- Resolution: [width x height]
- Frame rate: [fps]
- Format: [container/codec if known]
```

## JSON format

```json
{
  "summary": "string",
  "keyframes": [
    {"timestamp": "00:00:28.000", "description": "string"}
  ],
  "scenes": [
    {"start": "00:00", "end": "00:05", "description": "string"}
  ],
  "settings": ["string"],
  "characters_actions": ["string"],
  "camera_movement": "string",
  "visual_style": "string",
  "mood": "string",
  "audio_description": "string",
  "metadata": {
    "duration_seconds": 0,
    "resolution": "string",
    "frame_rate": 0,
    "format": "string"
  }
}
```
