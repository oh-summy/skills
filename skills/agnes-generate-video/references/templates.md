# Agnes Video V2.0 Prompt Templates

Use these templates as a starting point, then customize the bracketed parts.

## Quick presets

| Mode | What to pass | Typical params |
|---|---|---|
| Text-to-video | `--prompt` | `duration 5`, `1152x768`, `24fps` |
| Image-to-video | `--prompt` + `--image` | `duration 5`, same resolution as image |
| Multi-image video | `--prompt` + keyframes in `extra_body` | Advanced, edit payload manually |
| Keyframe animation | `--prompt` + multiple `--image`s | Advanced, edit payload manually |

## Templates

### 1. Text-to-video cinematic

```text
A cinematic [shot type] of [scene], [time of day], [lighting], [camera movement],
[subject action], atmospheric, high quality.
```

Example:

```text
A cinematic wide shot of a futuristic city at night with neon lights and flying cars,
slow camera pan across the skyline, atmospheric fog, high quality.
```

### 2. Image-to-video animation

Use with `--image <first-frame>`.

```text
Animate this scene: [subject] [action], [camera movement], [mood], smooth motion,
keep visual style consistent.
```

Example:

```text
Animate this scene: cherry blossoms falling gently in a Japanese garden,
slow camera drift forward, peaceful spring mood, smooth motion,
keep the painterly Ghibli-style visual consistent.
```

### 3. Product demo motion

```text
A smooth product showcase of [product], [rotation or movement], clean studio background,
professional lighting, subtle reflections, 4k commercial look.
```

Example:

```text
A smooth product showcase of a sleek smartwatch, slow 360-degree rotation,
clean gradient background, professional lighting, subtle reflections,
4k commercial look.
```

### 4. Social media short

```text
A fast-paced, eye-catching short clip for [platform], featuring [subject],
[colors/style], [camera movement], energetic mood, loop-friendly.
```

Example:

```text
A fast-paced, eye-catching short clip for TikTok, featuring abstract 3D shapes morphing,
bold purple and orange gradient style, dynamic camera zooms, energetic mood, loop-friendly.
```

### 5. Keyframe / transition animation

Use multiple image URLs as keyframes. This requires editing the payload manually
or extending the script.

```text
Generate a smooth cinematic transition between the keyframes, maintaining visual
consistency and natural camera movement.
```

### 6. Character / portrait animation

Use with `--image <portrait>`.

```text
Bring this portrait to life with subtle [expression/motion], gentle camera movement,
keep the subject's likeness and style consistent.
```

Example:

```text
Bring this portrait to life with subtle breathing and a gentle smile,
slight camera push-in, keep the subject's likeness and digital painting style consistent.
```

## Tips

- English prompts tend to be more stable than Chinese prompts.
- Mention camera movement (`slow pan`, `static shot`, `drone fly-over`) for stronger motion.
- Keep durations short (3–5s) for faster generation and lower failure rate.
- Use `duration` and `frame_rate` together; the script auto-computes valid `num_frames`.
