#!/usr/bin/env bash
# Analyze an image with Agnes 2.0 Flash and print the model response.
set -euo pipefail

BASE_URL="https://apihub.agnes-ai.com/v1"
DEFAULT_MODEL="agnes-2.0-flash"

usage() {
  cat <<'EOF'
Usage: understand_image.sh --image <path-or-url> --prompt <instruction> [options]

Options:
  --image    Local image path or publicly accessible URL
  --prompt   Analysis instruction
  --format   Output format: text, structured (default), json
  --json     Alias for --format json
  --model    Model name (default: agnes-2.0-flash)
  --help     Show this help
EOF
}

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

load_api_key() {
  # 1. Already-exported environment variable wins (includes variables from .zshrc/.bashrc).
  local key="${AGNES_API_KEY:-}"
  [[ -n "$key" ]] && { echo "$key"; return; }

  # 2. Search .env files from project-wide to skill-specific to global fallback.
  local env_files=(
    "$(pwd)/.env.local"
    "$(pwd)/.env"
    "$SKILL_DIR/.env.local"
    "$SKILL_DIR/.env"
    "$HOME/.env.local"
    "$HOME/.env"
  )

  for f in "${env_files[@]}"; do
    if [[ -f "$f" ]]; then
      key=$(grep '^AGNES_API_KEY=' "$f" | head -n1 | cut -d '=' -f2-)
      key="${key%$'\r'}"
      key="${key#\"}"; key="${key%\"}"
      key="${key#\'}"; key="${key%\'}"
      if [[ -n "$key" ]]; then
        export AGNES_API_KEY="$key"
        echo "$key"
        return
      fi
    fi
  done

  echo "AGNES_API_KEY not found. Set it as an environment variable or in one of these .env files: ${env_files[*]}" >&2
  exit 1
}

file_to_data_url() {
  local path="$1"
  local ext="${path##*.}"
  local mime="image/png"
  case "$ext" in
    png) mime="image/png" ;;
    jpg|jpeg) mime="image/jpeg" ;;
    webp) mime="image/webp" ;;
    gif) mime="image/gif" ;;
    *)
      if command -v file >/dev/null 2>&1; then
        mime=$(file -b --mime-type "$path" 2>/dev/null || echo "image/png")
      fi
      ;;
  esac
  local encoded
  encoded=$(base64 "$path" | tr -d '\n')
  echo "data:${mime};base64,${encoded}"
}

get_image_info() {
  local path="$1"
  local width="" height=""
  if command -v sips >/dev/null 2>&1; then
    width=$(sips -g pixelWidth "$path" 2>/dev/null | awk '/pixelWidth:/{print $2}')
    height=$(sips -g pixelHeight "$path" 2>/dev/null | awk '/pixelHeight:/{print $2}')
  elif command -v ffprobe >/dev/null 2>&1; then
    local wh
    wh=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$path" 2>/dev/null)
    width=$(echo "$wh" | cut -d 'x' -f1)
    height=$(echo "$wh" | cut -d 'x' -f2)
  fi
  if [[ -n "$width" && -n "$height" ]]; then
    echo "Image metadata: width=${width}, height=${height}, aspect_ratio=${width}:${height}."
  fi
}

build_prompt() {
  local user_prompt="$1"
  local format="$2"
  local metadata="$3"

  case "$format" in
    text)
      echo "$user_prompt"
      ;;
    structured)
      cat <<EOF
$user_prompt

Provide a structured analysis with the following sections:
- Summary (one sentence)
- Description (detailed)
- Subjects
- Style
- Color palette
- Composition
- Mood
- Text in image (if any)
- Metadata (dimensions, aspect ratio, format)

$metadata
EOF
      ;;
    json)
      cat <<EOF
$user_prompt

Return the result as valid JSON matching this schema:
{
  "summary": "string",
  "description": "string",
  "subjects": ["string"],
  "style": "string",
  "color_palette": ["string"],
  "composition": "string",
  "mood": "string",
  "text_in_image": "string",
  "metadata": {"width": 0, "height": 0, "aspect_ratio": "string", "format": "string"}
}

$metadata
EOF
      ;;
  esac
}

IMAGE=""
PROMPT=""
FORMAT="structured"
JSON_OUT=0
MODEL="$DEFAULT_MODEL"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --json) FORMAT="json"; JSON_OUT=1; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$IMAGE" || -z "$PROMPT" ]]; then
  echo "--image and --prompt are required." >&2
  usage >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install it from https://jqlang.github.io/jq/" >&2
  exit 1
fi

API_KEY=$(load_api_key)

IMAGE_URL="$IMAGE"
if [[ ! "$IMAGE" =~ ^(http://|https://|data:) ]]; then
  if [[ ! -f "$IMAGE" ]]; then
    echo "Image file not found: $IMAGE" >&2
    exit 1
  fi
  IMAGE_URL=$(file_to_data_url "$IMAGE")
fi

METADATA=""
if [[ ! "$IMAGE" =~ ^(http://|https://|data:) ]]; then
  METADATA=$(get_image_info "$IMAGE")
fi

PROMPT_TEXT=$(build_prompt "$PROMPT" "$FORMAT" "$METADATA")

PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$PROMPT_TEXT" \
  --arg image_url "$IMAGE_URL" \
  '{
    model: $model,
    messages: [{
      role: "user",
      content: [
        {type: "text", text: $prompt},
        {type: "image_url", image_url: {url: $image_url}}
      ]
    }],
    max_tokens: 2048
  }')

RESPONSE=$(curl -sS -X POST "${BASE_URL}/chat/completions" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [[ -z "$CONTENT" ]]; then
  echo "No content returned. Raw response:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  if echo "$CONTENT" | jq empty 2>/dev/null; then
    echo "$CONTENT" | jq .
  else
    echo "$CONTENT"
    echo "Warning: model did not return valid JSON." >&2
    exit 1
  fi
else
  echo "$CONTENT"
fi
