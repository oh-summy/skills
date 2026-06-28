#!/usr/bin/env bash
# Generate a video with Agnes Video V2.0 and poll until completion.
set -euo pipefail

BASE_URL="https://apihub.agnes-ai.com/v1"
API_BASE="${BASE_URL%/v1}"
DEFAULT_DOWNLOAD_DIR="${HOME}/AgnesAI/videos"
DEFAULT_WIDTH=1152
DEFAULT_HEIGHT=768
DEFAULT_DURATION=5
DEFAULT_FPS=24
DEFAULT_POLL=10
DEFAULT_MAX_WAIT=1800

usage() {
  cat <<'EOF'
Usage: generate_video.sh --prompt <text> [options]

Options:
  --prompt         Video generation prompt (required)
  --image          Starting image path or URL for image-to-video
  --width          Output width (default: 1152)
  --height         Output height (default: 768)
  --duration       Target duration in seconds (default: 5)
  --frame-rate     FPS (default: 24)
  --num-frames     Override duration; must be 8n+1 and <= 441
  --poll-interval  Seconds between status checks (default: 10)
  --max-wait       Max seconds to wait (default: 1800)
  --download       Local path or directory to save the MP4 (default: ~/AgnesAI/videos/agnes_video_<timestamp>.mp4)
  --no-open        Do not open the output folder after saving
  --help           Show this help
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

urlencode() {
  printf '%s' "$1" | jq -sRr @uri
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

nearest_valid_frames() {
  local n=$1
  if (( n > 441 )); then n=441; fi
  local k=$(( (n - 1) / 8 ))
  if (( k < 0 )); then k=0; fi
  echo $(( 8 * k + 1 ))
}

PROMPT=""
IMAGE=""
FOLDER_OPENED="false"
WIDTH="$DEFAULT_WIDTH"
HEIGHT="$DEFAULT_HEIGHT"
DURATION=""
NUM_FRAMES=""
FPS="$DEFAULT_FPS"
POLL="$DEFAULT_POLL"
MAX_WAIT="$DEFAULT_MAX_WAIT"
DOWNLOAD=""
NO_OPEN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --width) WIDTH="$2"; shift 2 ;;
    --height) HEIGHT="$2"; shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --frame-rate) FPS="$2"; shift 2 ;;
    --num-frames) NUM_FRAMES="$2"; shift 2 ;;
    --poll-interval) POLL="$2"; shift 2 ;;
    --max-wait) MAX_WAIT="$2"; shift 2 ;;
    --download) DOWNLOAD="$2"; shift 2 ;;
    --no-open) NO_OPEN=1; shift ;;
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

if [[ -z "$NUM_FRAMES" ]]; then
  if [[ -z "$DURATION" ]]; then
    DURATION="$DEFAULT_DURATION"
  fi
  RAW_FRAMES=$(awk "BEGIN {printf \"%d\", $DURATION * $FPS + 0.5}")
  NUM_FRAMES=$(nearest_valid_frames "$RAW_FRAMES")
else
  NUM_FRAMES=$(nearest_valid_frames "$NUM_FRAMES")
fi

PAYLOAD=$(jq -n \
  --arg model "agnes-video-v2.0" \
  --arg prompt "$PROMPT" \
  --argjson width "$WIDTH" \
  --argjson height "$HEIGHT" \
  --argjson num_frames "$NUM_FRAMES" \
  --argjson frame_rate "$FPS" \
  '{
    model: $model,
    prompt: $prompt,
    width: $width,
    height: $height,
    num_frames: $num_frames,
    frame_rate: $frame_rate
  }')

if [[ -n "$IMAGE" ]]; then
  IMAGE_URL="$IMAGE"
  if [[ ! "$IMAGE" =~ ^(http://|https://|data:) ]]; then
    if [[ ! -f "$IMAGE" ]]; then
      echo "Image file not found: $IMAGE" >&2
      exit 1
    fi
    IMAGE_URL=$(file_to_data_url "$IMAGE")
  fi
  PAYLOAD=$(echo "$PAYLOAD" | jq --arg image_url "$IMAGE_URL" '.image = $image_url')
fi

echo "Creating video task..." >&2
CREATE_RESP=$(curl -sS -X POST "${BASE_URL}/videos" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

VIDEO_ID=$(echo "$CREATE_RESP" | jq -r '.video_id // empty')
TASK_ID=$(echo "$CREATE_RESP" | jq -r '.task_id // empty')

if [[ -z "$VIDEO_ID" ]]; then
  echo "Failed to create video task. Response:" >&2
  echo "$CREATE_RESP" >&2
  exit 1
fi

ENCODED_VIDEO_ID=$(urlencode "$VIDEO_ID")

echo "Task created: $TASK_ID (video_id: $VIDEO_ID)" >&2

START_TIME=$(date +%s)
VIDEO_URL=""
while true; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))
  if (( ELAPSED > MAX_WAIT )); then
    echo "Timed out after ${MAX_WAIT}s." >&2
    exit 1
  fi

  STATUS_RESP=$(curl -sS "${API_BASE}/agnesapi?video_id=${ENCODED_VIDEO_ID}" \
    -H "Authorization: Bearer ${API_KEY}")

  STATUS=$(echo "$STATUS_RESP" | jq -r '.status // empty')
  PROGRESS=$(echo "$STATUS_RESP" | jq -r '.progress // empty')

  echo "Status: ${STATUS:-unknown} | Progress: ${PROGRESS:-0}%" >&2

  if [[ "$STATUS" == "completed" ]]; then
    VIDEO_URL=$(echo "$STATUS_RESP" | jq -r '.remixed_from_video_id // .url // .video_url // empty')
    break
  fi

  if [[ "$STATUS" == "failed" || "$STATUS" == "cancelled" ]]; then
    echo "Video generation failed." >&2
    echo "$STATUS_RESP" >&2
    exit 1
  fi

  sleep "$POLL"
done

if [[ -n "$VIDEO_URL" ]]; then
  if [[ -z "$DOWNLOAD" ]]; then
    mkdir -p "$DEFAULT_DOWNLOAD_DIR"
    DOWNLOAD="$DEFAULT_DOWNLOAD_DIR/agnes_video_$(date +%s).mp4"
  elif [[ -d "$DOWNLOAD" ]]; then
    DOWNLOAD="$DOWNLOAD/agnes_video_$(date +%s).mp4"
  fi
  echo "Downloading video to $DOWNLOAD..." >&2
  curl -sSL -o "$DOWNLOAD" "$VIDEO_URL"

  if [[ "$NO_OPEN" -eq 0 ]]; then
    local output_dir
    output_dir=$(dirname "$DOWNLOAD")
    echo "Opening output folder..." >&2
    open_folder "$output_dir"
    FOLDER_OPENED="true"
  else
    FOLDER_OPENED="false"
  fi
fi

echo "$STATUS_RESP" | jq --arg video_url "$VIDEO_URL" --arg file "$DOWNLOAD" --arg folder_opened "$FOLDER_OPENED" '. + {final_video_url: $video_url, saved_file: $file, folder_opened: $folder_opened}'
