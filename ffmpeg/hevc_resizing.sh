#!/bin/bash

# 인수: <full_output_path> (MediaMTX의 $MTX_PATH 변수가 여기에 전달됩니다)
FULL_OUTPUT_PATH="$1"

# 필수 인수가 없으면 사용법을 출력하고 종료
if [ -z "$FULL_OUTPUT_PATH" ]; then
  echo "Usage: $0 <MTX_PATH>"
  echo "Example: $0 qnd-6011-02/H265/FHD"
  exit 1
fi

# $MTX_PATH를 파싱하여 BASE_NAME과 SIZE_NAME을 추출합니다.
# 예시: FULL_OUTPUT_PATH = "qnd-6011-02/H265/HD"
# BASE_NAME = "qnd-6011-02" (첫 번째 슬래시 이전 부분)
BASE_NAME=$(echo "$FULL_OUTPUT_PATH" | cut -d'/' -f1)
# SIZE_NAME = "HD" (마지막 슬래시 이후 부분)
SIZE_NAME=$(echo "$FULL_OUTPUT_PATH" | cut -d'/' -f3)

# 필수 인수가 없으면 사용법을 출력하고 종료
if [ -z "$BASE_NAME" ] || [ -z "$SIZE_NAME" ]; then
  echo "Usage: $0 <base_name> <size_name>"
  echo "Example: $0 qnd-6011-02 FHD"
  exit 1
fi

declare -A SIZES
SIZES["FHD"]="1920x1080:5M"
SIZES["HD"]="1280x720:3M"
SIZES["FWVGA"]="854x480:1M"
SIZES["VGA"]="640x480:1M"

if [ -z "${SIZES[$SIZE_NAME]}" ]; then
  echo "Error: Unknown size name '${SIZE_NAME}'. Supported sizes are: ${!SIZES[*]}"
  exit 1
fi

# 사이즈 정보에서 해상도와 비트레이트를 추출합니다.
SIZE_INFO=${SIZES[$SIZE_NAME]}
RESOLUTION=$(echo "$SIZE_INFO" | cut -d':' -f1)
BITRATE=$(echo "$SIZE_INFO" | cut -d':' -f2)


echo "Starting FFmpeg for $BASE_NAME/H265/$SIZE_NAME (Input: $BASE_NAME/H265, Resolution: ${RESOLUTION}, Bitrate: ${BITRATE})"

ffmpeg \
  -loglevel quiet \
  -hwaccel cuda \
  -fflags +genpts \
  -rtsp_transport tcp \
  -c:v hevc_cuvid \
  -i "rtsp://localhost:$RTSP_PORT/$BASE_NAME/H265" \
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
  -f rtsp "rtsp://localhost:$RTSP_PORT/$BASE_NAME/H265/$SIZE_NAME"