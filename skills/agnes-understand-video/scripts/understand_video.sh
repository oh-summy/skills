#!/usr/bin/env bash
# Understand a video by sampling frames and analyzing them with Agnes 2.0 Flash.
set -euo pipefail

BASE_URL="https://apihub.agnes-ai.com/v1"
DEFAULT_MODEL="agnes-2.0-flash"
DEFAULT_FRAMES=5
DEFAULT_MAX_WIDTH=512
DEFAULT_WINDOW=2

usage() {
  cat <<'EOF'
Usage: understand_video.sh --video <path-or-url> --prompt <instruction> [options]

Options:
  --video        Local video path or publicly accessible URL (required)
  --prompt       Analysis instruction (required)
  --timestamp    Analyze around this timestamp, e.g. 30, 30.5, 00:00:30, 0:30
  --window       Seconds around --timestamp to sample (default: 2)
  --frames       Number of frames to sample (default: 5)
  --format       Output format: text, structured (default), json
  --json         Alias for --format json
  --max-width    Resize frames to this width to save tokens (default: 512)
  --model        Model name (default: agnes-2.0-flash)
  --help         Show this help
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

parse_timestamp() {
  local ts="$1"
  awk -F: '{
    if (NF == 3) { printf "%.3f", ($1*3600)+($2*60)+$3 }
    else if (NF == 2) { printf "%.3f", ($1*60)+$2 }
    else { printf "%.3f", $1 }
  }' <<< "$ts"
}

format_time() {
  local seconds="$1"
  awk -v s="$seconds" '{
    h = int(s/3600)
    m = int((s - h*3600)/60)
    sec = s - h*3600 - m*60
    printf "%02d:%02d:%06.3f", h, m, sec
  }' <<< ""
}

get_video_info() {
  local path="$1"
  local duration width height fps
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$path" 2>/dev/null | tr -d '\r')
  width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$path" 2>/dev/null | tr -d '\r')
  height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$path" 2>/dev/null | tr -d '\r')
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$path" 2>/dev/null | tr -d '\r')
  echo "Video metadata: duration=${duration}s, resolution=${width}x${height}, frame_rate=${fps}."
}

build_prompt() {
  local user_prompt="$1"
  local format="$2"
  local metadata="$3"
  local keyframes="$4"

  case "$format" in
    text)
      cat <<EOF
$user_prompt

Extracted keyframes at: $keyframes
EOF
      ;;
    structured)
      cat <<EOF
$user_prompt

Extracted keyframes at: $keyframes

Provide a structured analysis with the following sections:
- Summary (one sentence)
- Keyframes analyzed (describe what happens at each extracted timestamp)
- Scene-by-scene description
- Settings
- Characters / actions
- Camera movement
- Visual style
- Mood / tone
- Audio description (if inferable)
- Metadata (duration, resolution, frame rate, format)

$metadata
EOF
      ;;
    json)
      cat <<EOF
$user_prompt

Extracted keyframes at: $keyframes

Return the result as valid JSON matching this schema:
{
  "summary": "string",
  "keyframes": [{"timestamp": "00:00:00.000", "description": "string"}],
  "scenes": [{"start": "00:00", "end": "00:05", "description": "string"}],
  "settings": ["string"],
  "characters_actions": ["string"],
  "camera_movement": "string",
  "visual_style": "string",
  "mood": "string",
  "audio_description": "string",
  "metadata": {"duration_seconds": 0, "resolution": "string", "frame_rate": 0, "format": "string"}
}

$metadata
EOF
      ;;
  esac
}

VIDEO=""
PROMPT=""
TIMESTAMP=""
WINDOW="$DEFAULT_WINDOW"
FRAMES="$DEFAULT_FRAMES"
FORMAT="structured"
JSON_OUT=0
MAX_WIDTH="$DEFAULT_MAX_WIDTH"
MODEL="$DEFAULT_MODEL"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --video) VIDEO="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --timestamp) TIMESTAMP="$2"; shift 2 ;;
    --window) WINDOW="$2"; shift 2 ;;
    --frames) FRAMES="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --json) FORMAT="json"; JSON_OUT=1; shift ;;
    --max-width) MAX_WIDTH="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$VIDEO" || -z "$PROMPT" ]]; then
  echo "--video and --prompt are required." >&2
  usage >&2
  exit 1
fi

for cmd in curl jq ffmpeg ffprobe; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required. Install it and try again." >&2
    exit 1
  fi
done

API_KEY=$(load_api_key)

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

VIDEO_PATH="$VIDEO"
if [[ "$VIDEO" =~ ^(http://|https://) ]]; then
  echo "Downloading video..." >&2
  VIDEO_PATH="$TMPDIR/video.mp4"
  curl -sSL -o "$VIDEO_PATH" "$VIDEO"
fi

if [[ ! -f "$VIDEO_PATH" ]]; then
  echo "Video file not found: $VIDEO" >&2
  exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_PATH")
DURATION=${DURATION%$'\r'}

METADATA=$(get_video_info "$VIDEO_PATH")

if [[ -n "$TIMESTAMP" ]]; then
  TS_SECONDS=$(parse_timestamp "$TIMESTAMP")
  START=$(awk -v ts="$TS_SECONDS" -v w="$WINDOW" 'BEGIN {print (ts>w)?ts-w:0}')
  END=$(awk -v ts="$TS_SECONDS" -v w="$WINDOW" -v dur="$DURATION" 'BEGIN {print (ts+w<dur)?ts+w:dur}')
  if [[ "$(awk -v s="$START" -v e="$END" 'BEGIN {print (s>=e)?1:0}')" == "1" ]]; then
    echo "Timestamp $TIMESTAMP is out of video range (duration: ${DURATION}s)." >&2
    exit 1
  fi
  echo "Analyzing around $(format_time "$TS_SECONDS") with ${WINDOW}s window (frames from $(format_time "$START") to $(format_time "$END"))..." >&2
else
  START=0
  END="$DURATION"
  echo "Extracting $FRAMES frames across full video..." >&2
fi

FRAME_TIMES=()
for i in $(seq 0 $((FRAMES - 1))); do
  t=$(awk -v start="$START" -v end="$END" -v i="$i" -v n="$FRAMES" 'BEGIN {printf "%.6f", start + (end-start)*(i+1)/(n+1)}')
  FRAME_TIMES+=("$t")
done

KEYFRAME_LABELS=()
IMAGES_JSON="["
for i in "${!FRAME_TIMES[@]}"; do
  t="${FRAME_TIMES[$i]}"
  label=$(format_time "$t")
  KEYFRAME_LABELS+=("$label")
  out="$TMPDIR/frame_$(printf '%03d' $i).jpg"
  ffmpeg -v error -ss "$t" -i "$VIDEO_PATH" -vf "scale=${MAX_WIDTH}:-2" -vframes 1 -q:v 2 "$out"
  encoded=$(base64 "$out" | tr -d '\n')
  IMAGES_JSON+="{\"type\":\"image_url\",\"image_url\":{\"url\":\"data:image/jpeg;base64,${encoded}\"}},"
done
IMAGES_JSON="${IMAGES_JSON%,}]"

KEYFRAME_STRING=""
for label in "${KEYFRAME_LABELS[@]}"; do
  KEYFRAME_STRING+="$label, "
done
KEYFRAME_STRING="${KEYFRAME_STRING%, }"
PROMPT_TEXT=$(build_prompt "$PROMPT" "$FORMAT" "$METADATA" "$KEYFRAME_STRING")

PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$PROMPT_TEXT" \
  --argjson images "$IMAGES_JSON" \
  '{
    model: $model,
    messages: [{
      role: "user",
      content: [{type: "text", text: $prompt}] + $images
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
  # Models sometimes wrap JSON in markdown fences; strip them before validating.
  CLEAN_CONTENT=$(echo "$CONTENT" | sed -n '/^```json$/,/^```$/p' | sed '1d;$d')
  if [[ -z "$CLEAN_CONTENT" ]]; then
    CLEAN_CONTENT="$CONTENT"
  fi
  if echo "$CLEAN_CONTENT" | jq empty 2>/dev/null; then
    echo "$CLEAN_CONTENT" | jq .
  else
    echo "$CONTENT"
    echo "Warning: model did not return valid JSON." >&2
    exit 1
  fi
else
  echo "Extracted keyframes at: $KEYFRAME_STRING"
  echo
  echo "$CONTENT"
fi
