# Agnes Understand Image — Output Schema

When analyzing an image, return structured information in this format.

## Text format

```markdown
## Summary
One-sentence overview.

## Description
Detailed visual description.

## Subjects
- Main subject 1
- Main subject 2

## Style
Art / photography style.

## Color palette
- Dominant color 1
- Dominant color 2

## Composition
Framing, perspective, depth.

## Mood
Atmosphere or emotional tone.

## Text in image
Any readable text (OCR).

## Metadata
- Dimensions: [width x height]
- Aspect ratio: [ratio]
- Format: [image format if known]
```

## JSON format

```json
{
  "summary": "string",
  "description": "string",
  "subjects": ["string"],
  "style": "string",
  "color_palette": ["string"],
  "composition": "string",
  "mood": "string",
  "text_in_image": "string",
  "metadata": {
    "width": 0,
    "height": 0,
    "aspect_ratio": "string",
    "format": "string"
  }
}
```
