#!/usr/bin/env bash
# (C) 2026 MrLavinci <mrlavinci@gmail.com>
# Dieses Script ist unter der GNU General Public License v3.0 lizenziert.
# Details findest du unter <https://www.gnu.org/licenses/gpl-3.0.html>.
set -euo pipefail
export LC_ALL=C

if [ "$#" -lt 2 ]; then
  echo "Nutzung: $0 <input> <output>"
  exit 1
fi

INPUT="$1"
OUTPUT="$2"

if [ ! -f "$INPUT" ]; then
  echo "❌ Input-Datei nicht gefunden: $INPUT"
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

# Gesamtdauer in Sekunden holen
DURATION=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")

if [ -z "$DURATION" ]; then
  echo "❌ Konnte Videodauer nicht lesen."
  exit 1
fi

# Dauer hübsch formatieren
DUR_INT=$(awk "BEGIN {printf \"%d\", $DURATION}")
DUR_FMT=$(printf "%02d:%02d:%02d" $((DUR_INT/3600)) $(((DUR_INT%3600)/60)) $((DUR_INT%60)))

# Temporäre Datei für Fortschritt
PROGRESS_FILE=$(mktemp)
trap 'rm -f "$PROGRESS_FILE"' EXIT

# FFmpeg im Hintergrund starten
ffmpeg -y \
  -i "$INPUT" \
  -c:v hevc_amf -usage transcoding -quality speed -b:v 6M \
  -c:a aac -b:a 192k \
  -progress "$PROGRESS_FILE" -nostats \
  "$OUTPUT" >/dev/null 2>&1 &

FFMPEG_PID=$!

echo "🚀 Rendering gestartet..."
echo "📥 Input : $INPUT"
echo "📤 Output: $OUTPUT"
echo "🎞️  Dauer : $DUR_FMT"
echo

# Für sanftere ETA einen geglätteten speed-Wert nutzen
SMOOTH_SPEED=""

draw_bar() {
  local percent_int="$1"
  local width=24
  local filled=$((percent_int * width / 100))
  local empty=$((width - filled))

  local bar=""
  if [ "$filled" -gt 0 ]; then
    bar="$(printf "%0.s█" $(seq 1 "$filled"))"
  fi
  if [ "$empty" -gt 0 ]; then
    bar="${bar}$(printf "%0.s░" $(seq 1 "$empty"))"
  fi
  printf "%s" "$bar"
}

while kill -0 "$FFMPEG_PID" 2>/dev/null; do
  sleep 1

  if [ -f "$PROGRESS_FILE" ]; then
    OUT_TIME_MS=$(grep '^out_time_ms=' "$PROGRESS_FILE" | tail -n1 | cut -d= -f2 || true)
    SPEED_RAW=$(grep '^speed=' "$PROGRESS_FILE" | tail -n1 | cut -d= -f2 || true)
    FPS_RAW=$(grep '^fps=' "$PROGRESS_FILE" | tail -n1 | cut -d= -f2 || true)
    TOTAL_SIZE=$(grep '^total_size=' "$PROGRESS_FILE" | tail -n1 | cut -d= -f2 || true)

    if [ -n "${OUT_TIME_MS:-}" ] && [ "$OUT_TIME_MS" -gt 0 ]; then
      PROCESSED_SEC=$(awk "BEGIN {printf \"%.2f\", $OUT_TIME_MS/1000000}")
      PERCENT=$(awk "BEGIN {printf \"%.1f\", ($PROCESSED_SEC/$DURATION)*100}")
      PERCENT_INT=$(awk "BEGIN {printf \"%d\", ($PROCESSED_SEC/$DURATION)*100}")
      [ "$PERCENT_INT" -gt 100 ] && PERCENT_INT=100

      # speed wie "5.05x" -> "5.05"
      SPEED="${SPEED_RAW%x}"

      if [ -n "${SPEED:-}" ] && awk "BEGIN {exit !($SPEED > 0)}"; then
        if [ -z "$SMOOTH_SPEED" ]; then
          SMOOTH_SPEED="$SPEED"
        else
          SMOOTH_SPEED=$(awk "BEGIN {printf \"%.2f\", ($SMOOTH_SPEED*0.7)+($SPEED*0.3)}")
        fi

        REMAINING_VIDEO_SEC=$(awk "BEGIN {printf \"%.2f\", $DURATION-$PROCESSED_SEC}")
        ETA_SEC=$(awk "BEGIN {printf \"%d\", $REMAINING_VIDEO_SEC/$SMOOTH_SPEED}")

        ETA_H=$((ETA_SEC/3600))
        ETA_M=$(((ETA_SEC%3600)/60))
        ETA_S=$((ETA_SEC%60))
        ETA_FMT=$(printf "%02d:%02d:%02d" "$ETA_H" "$ETA_M" "$ETA_S")

        ELAPSED=$(ps -o etime= -p "$FFMPEG_PID" | tr -d ' ')
        BAR=$(draw_bar "$PERCENT_INT")

        SIZE_MB="0.0"
        if [ -n "${TOTAL_SIZE:-}" ] && [ "$TOTAL_SIZE" -gt 0 ] 2>/dev/null; then
          SIZE_MB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_SIZE/1024/1024}")
        fi

        FPS_SHOW="--"
        if [ -n "${FPS_RAW:-}" ]; then
          FPS_SHOW="$FPS_RAW"
        fi

        printf "\r🎬 [%s] %5.1f%% | 🚀 %sx | 🎞️ %sfps | 📦 %s MiB | ETA %s | ⏳ %s" \
          "$BAR" "$PERCENT" "$SMOOTH_SPEED" "$FPS_SHOW" "$SIZE_MB" "$ETA_FMT" "$ELAPSED"
      fi
    fi
  fi
done

wait "$FFMPEG_PID"
echo
echo "✅ Fertig: $OUTPUT"
