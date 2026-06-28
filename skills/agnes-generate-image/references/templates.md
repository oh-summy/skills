# Agnes Image 2.1 Flash Prompt Templates

Pick a template, fill in the bracketed placeholders, or use them as a starting point for your own prompt.

## Quick presets

| Use case | Recommended size | Aspect ratio |
|---|---|---|
| Social media post (square) | `1024x1024` | 1:1 |
| Social media story / vertical | `768x1344` | 9:16 |
| Banner / cover | `1792x1024` | 16:9 |
| Wallpaper / landscape | `1344x768` | 16:9 |
| Product shot | `1024x1024` or `1152x768` | 1:1 or 3:2 |
| Poster / portrait | `1024x1344` | 3:4 |

## Templates

### 1. Creative design / concept art

```text
A [style] concept art of [subject], [environment], [lighting], [mood].
Highly detailed, atmospheric, cinematic composition.
```

Example:

```text
A cyberpunk concept art of a neon-lit street market in Tokyo, rainy night,
reflections on wet pavement, moody blue and magenta lighting, cinematic composition.
```

### 2. Marketing / product visual

```text
A clean product photo of [product] on [surface/background], [lighting],
[angle], minimal shadows, professional commercial photography style.
```

Example:

```text
A clean product photo of a matte black wireless headphone on a marble surface,
soft studio lighting, 3/4 angle, professional commercial photography style.
```

### 3. Social media creative

```text
A bold, eye-catching [platform] post image featuring [subject], [colors],
[text/mood], flat design or 3D render style, high contrast.
```

Example:

```text
A bold Instagram post image featuring a rocket launch, deep purple and orange gradient,
energetic and inspiring mood, 3D render style, high contrast.
```

### 4. High-density visual scene

```text
A richly detailed scene of [setting], filled with [elements], [time of day],
[art style], deep layers, intricate textures.
```

Example:

```text
A richly detailed scene of a fantasy library inside a giant tree, filled with glowing books,
floating candles and spiral staircases, golden hour light, painterly digital art style,
deep layers, intricate textures.
```

### 5. Image transformation / style transfer

Use with `--image <reference>`.

```text
Transform this image into [target style], keeping the original composition and subject.
[lighting change], [color grading], [mood shift].
```

Example:

```text
Transform this image into a hand-drawn watercolor illustration,
keeping the original composition and subject. Soft natural lighting,
pastel color grading, calm and nostalgic mood.
```

### 6. Thumbnail / banner / app asset

```text
A [dimensions]-friendly [asset type] showing [subject], clear focal point,
bold colors, readable negative space, [style].
```

Example:

```text
A YouTube thumbnail-friendly image showing a surprised programmer looking at a screen,
clear focal point, bold orange and dark blue colors, readable negative space,
3D cartoon style.
```

## Negative prompts / constraints

Add these at the end of a prompt when needed:

- `no text, no watermark, no signature`
- `minimalist, clean background`
- `photorealistic, 8k, highly detailed`
- `anime style, cel-shaded, vibrant colors`
