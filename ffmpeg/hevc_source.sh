#!/bin/bash

# 인수: <source_name>
SOURCE_NAME="$1"

# 필수 인수가 없으면 사용법을 출력하고 종료
if [ -z "$SOURCE_NAME" ]; then
  echo "Usage: $0 <source_name>"
  echo "Example: $0 Factory"
  exit 1
fi

# JSON 파일 경로
JSON_FILE="/sources/sources.json"

# jq가 설치되어 있는지 확인
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed. Please install jq first."
  exit 1
fi

# JSON 파일이 존재하는지 확인
if [ ! -f "$JSON_FILE" ]; then
  echo "Error: Sources metadata file '$JSON_FILE' does not exist"
  exit 1
fi

# JSON에서 소스 정보 추출
SOURCE_INFO=$(jq -r --arg name "$SOURCE_NAME" '.sources[] | select(.name == $name)' "$JSON_FILE")

if [ -z "$SOURCE_INFO" ]; then
  echo "Error: Source '$SOURCE_NAME' not found in metadata"
  echo "Available sources:"
  jq -r '.sources[].name' "$JSON_FILE"
  exit 1
fi

# 소스 정보 파싱
FILE_NAME=$(echo "$SOURCE_INFO" | jq -r '.file')
SIZE_NAME=$(echo "$SOURCE_INFO" | jq -r '.size')
SOURCE_FILE="/sources/$FILE_NAME"

# 소스 파일이 존재하는지 확인
if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: Source file '$SOURCE_FILE' does not exist"
  exit 1
fi

declare -A SIZES
SIZES["FHD"]="1920x1080:5M"
SIZES["HD"]="1280x720:3M"
SIZES["FWVGA"]="854x480:1M"
SIZES["VGA"]="640x480:1M"

if [ -z "${SIZES[$SIZE_NAME]}" ]; then
  echo "Error: Unknown size name '${SIZE_NAME}' in metadata. Supported sizes are: ${!SIZES[*]}"
  exit 1
fi

# 사이즈 정보에서 해상도와 비트레이트를 추출합니다.
SIZE_INFO=${SIZES[$SIZE_NAME]}
RESOLUTION=$(echo "$SIZE_INFO" | cut -d':' -f1)
BITRATE=$(echo "$SIZE_INFO" | cut -d':' -f2)

echo "Starting FFmpeg for $SOURCE_NAME (Input: $SOURCE_FILE, Resolution: ${RESOLUTION}, Bitrate: ${BITRATE})"

ffmpeg \
  -loglevel quiet \
  -hwaccel cuda \
  -fflags +genpts \
  -re \
  -stream_loop -1 \
  -i "$SOURCE_FILE" \
  -c:v hevc_nvenc \
  -preset:v p2 \
  -g 30 \
  -bf 0 \
  -profile:v main \
  -s "$RESOLUTION" \
  -b:v "$BITRATE" \
  -bufsize "$BITRATE" \
  -tune:v ll \
  -max_muxing_queue_size 1024 \
  -f rtsp "rtsp://localhost:$RTSP_PORT/$SOURCE_NAME/H265"