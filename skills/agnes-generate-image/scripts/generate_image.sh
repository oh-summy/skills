#!/usr/bin/env bash
# Generate or edit an image with Agnes Image 2.1 Flash.
set -euo pipefail

BASE_URL="https://apihub.agnes-ai.com/v1"
DEFAULT_MODEL="agnes-image-2.1-flash"
DEFAULT_OUTPUT_DIR="${HOME}/AgnesAI/images"

usage() {
  cat <<'EOF'
Usage: generate_image.sh --prompt <text> [options]

Options:
  --prompt           Image generation prompt (required)
  --size             Output size, e.g. 1024x768, 1024x1024, 768x1024 (default: 1024x768)
  --image            Reference image path or URL for image-to-image
  --response-format  url or base64 (default: base64; base64 saves images locally)
  --n                Number of images (default: 1)
  --output-dir       Directory for saved images (default: ~/AgnesAI/images)
  --no-open          Do not open the output folder after saving
  --model            Model name (default: agnes-image-2.1-flash)
  --help             Show this help
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

open_folder() {
  local dir="$1"
  case "$(uname -s)" in
    Darwin) open "$dir" ;;
    Linux) xdg-open "$dir" >/dev/null 2>&1 || true ;;
    CYGWIN*|MINGW*|MSYS*)
      local win_dir
      win_dir=$(cygpath -w "$dir" 2>/dev/null || echo "$dir")
      explorer "$win_dir" >/dev/null 2>&1 || true
      ;;
  esac
}

PROMPT=""
SIZE="1024x768"
IMAGE=""
RESPONSE_FORMAT="base64"
N=1
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
NO_OPEN=0
MODEL="$DEFAULT_MODEL"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2 ;;
    --size) SIZE="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --response-format) RESPONSE_FORMAT="$2"; shift 2 ;;
    --n) N="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --no-open) NO_OPEN=1; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$PROMPT" ]]; then
  echo "--prompt is required." >&2
  usage >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install it from https://jqlang.github.io/jq/" >&2
  exit 1
fi

API_KEY=$(load_api_key)

PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$PROMPT" \
  --arg size "$SIZE" \
  --argjson n "$N" \
  --arg response_format "$RESPONSE_FORMAT" \
  '{
    model: $model,
    prompt: $prompt,
    size: $size,
    n: $n,
    extra_body: {response_format: $response_format}
  }')

if [[ -n "$IMAGE" ]]; then
  IMAGE_URL="$IMAGE"
  if [[ ! "$IMAGE" =~ ^(http://|https://|data:) ]]; then
    if [[ ! -f "$IMAGE" ]]; then
      echo "Reference image file not found: $IMAGE" >&2
      exit 1
    fi
    IMAGE_URL=$(file_to_data_url "$IMAGE")
  fi
  PAYLOAD=$(echo "$PAYLOAD" | jq --arg image_url "$IMAGE_URL" '.image = [$image_url]')
fi

if [[ "$RESPONSE_FORMAT" == "base64" ]]; then
  if [[ -n "$IMAGE" ]]; then
    # Image-to-image base64 output
    PAYLOAD=$(echo "$PAYLOAD" | jq '.extra_body.response_format = "b64_json"')
  else
    # Text-to-image base64 output: Agnes currently returns a URL even when
    # return_base64 is true, so we keep extra_body as "url" and download later.
    PAYLOAD=$(echo "$PAYLOAD" | jq '.return_base64 = true | .extra_body.response_format = "url"')
  fi
fi

RESPONSE=$(curl -sS -X POST "${BASE_URL}/images/generations" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [[ "$RESPONSE_FORMAT" == "base64" ]]; then
  mkdir -p "$OUTPUT_DIR"
  i=0
  RESULTS="[]"
  while read -r item; do
    [[ -z "$item" ]] && continue
    b64=$(echo "$item" | jq -r '.b64_json // empty')
    url=$(echo "$item" | jq -r '.url // empty')
    revised=$(echo "$item" | jq -r '.revised_prompt // empty')
    filename="agnes_image_$(printf '%03d' $i).png"
    filepath="${OUTPUT_DIR}/${filename}"

    if [[ -n "$b64" ]]; then
      echo "$b64" | base64 -d > "$filepath"
    elif [[ -n "$url" ]]; then
      curl -sSL -o "$filepath" "$url"
    else
      continue
    fi

    RESULTS=$(echo "$RESULTS" | jq --arg file "$filepath" --arg revised "$revised" '. + [{file: $file, revised_prompt: $revised}]')
    i=$((i + 1))
  done < <(echo "$RESPONSE" | jq -c '.data[]')
  CREATED=$(echo "$RESPONSE" | jq -r '.created // empty')
  FOLDER_OPENED="false"
  if [[ "$NO_OPEN" -eq 0 ]]; then
    echo "Opening output folder..." >&2
    open_folder "$OUTPUT_DIR"
    FOLDER_OPENED="true"
  fi
  echo "$RESULTS" | jq --arg created "$CREATED" --arg folder_opened "$FOLDER_OPENED" '{created: $created, images: ., folder_opened: $folder_opened}'
else
  echo "$RESPONSE" | jq .
fi
