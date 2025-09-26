<h1 align="center">
  <a href="https://mediamtx.org">
    <img src="logo.png" alt="MediaMTX">
  </a>

  <br>
  <br>

  [![Website](https://img.shields.io/badge/website-mediamtx.org-1c94b5)](https://mediamtx.org)
  [![Test](https://github.com/bluenviron/mediamtx/actions/workflows/code_test.yml/badge.svg)](https://github.com/bluenviron/mediamtx/actions/workflows/code_test.yml)
  [![Lint](https://github.com/bluenviron/mediamtx/actions/workflows/code_lint.yml/badge.svg)](https://github.com/bluenviron/mediamtx/actions/workflows/code_lint.yml)
  [![CodeCov](https://codecov.io/gh/bluenviron/mediamtx/branch/main/graph/badge.svg)](https://app.codecov.io/gh/bluenviron/mediamtx/tree/main)
  [![Release](https://img.shields.io/github/v/release/bluenviron/mediamtx)](https://github.com/bluenviron/mediamtx/releases)
  [![Docker Hub](https://img.shields.io/badge/docker-bluenviron/mediamtx-blue)](https://hub.docker.com/r/bluenviron/mediamtx)
</h1>

<br>

_MediaMTX_ is a ready-to-use and zero-dependency real-time media server and media proxy that allows to publish, read, proxy, record and playback video and audio streams. It has been conceived as a "media router" that routes media streams from one end to the other.

<div align="center">

  |[Installation](https://mediamtx.org/docs/kickoff/installation)|[Documentation](https://mediamtx.org/docs/kickoff/introduction)|
  |-|-|

</div>

<h3>Features</h3>

- [Publish](https://mediamtx.org/docs/usage/publish) live streams to the server with SRT, WebRTC, RTSP, RTMP, HLS, MPEG-TS, RTP
- [Read](https://mediamtx.org/docs/usage/read) live streams from the server with SRT, WebRTC, RTSP, RTMP, HLS
- Streams are automatically converted from a protocol to another
- Serve several streams at once in separate paths
- Reload the configuration without disconnecting existing clients (hot reloading)
- [Record](https://mediamtx.org/docs/usage/record) streams to disk in fMP4 or MPEG-TS format
- [Playback](https://mediamtx.org/docs/usage/playback) recorded streams
- [Authenticate](https://mediamtx.org/docs/usage/authentication) users with internal, HTTP or JWT authentication
- [Forward](https://mediamtx.org/docs/usage/forward) streams to other servers
- [Proxy](https://mediamtx.org/docs/usage/proxy) requests to other servers
- [Control](https://mediamtx.org/docs/usage/control-api) the server through the Control API
- [Extract metrics](https://mediamtx.org/docs/usage/metrics) from the server in a Prometheus-compatible format
- [Monitor performance](https://mediamtx.org/docs/usage/performance) to investigate CPU and RAM consumption
- [Run hooks](https://mediamtx.org/docs/usage/hooks) (external commands) when clients connect, disconnect, read or publish streams
- Compatible with Linux, Windows and macOS, does not require any dependency or interpreter, it's a single executable
- ...and many [others](https://mediamtx.org/docs/kickoff/introduction).


### Standalone binary

1. Download and extract a standalone binary from the [release page](https://github.com/bluenviron/mediamtx/releases) that corresponds to your operating system and architecture.

2. Start the server:

   ```sh
   ./mediamtx
   ```

### Docker image

Download and launch the image:

```
docker run --rm -it --network=host bluenviron/mediamtx:latest
```

```
docker run \
  -it \
  --rm \
  --name=mediamtx \
  --gpus all \
  -v ./mediamtx.yml:/mediamtx.yml \
  -v ./ffmpeg:/ffmpeg \
  -p 8554:8554 \
  bluenviron/mediamtx:nvidia-ffmpeg
```

Available images:

|name|FFmpeg included|RPI Camera support|
|----|---------------|------------------|
|bluenviron/mediamtx:latest|:x:|:x:|
|bluenviron/mediamtx:latest-ffmpeg|:heavy_check_mark:|:x:|
|bluenviron/mediamtx:latest-rpi|:x:|:heavy_check_mark:|
|bluenviron/mediamtx:latest-ffmpeg-rpi|:heavy_check_mark:|:heavy_check_mark:|

The `--network=host` flag is mandatory for RTSP to work, since Docker can change the source port of UDP packets for routing reasons, and this doesn't allow the server to identify the senders of the packets.

If the `--network=host` cannot be used (for instance, it is not compatible with Windows or Kubernetes), you can disable the RTSP UDP transport protocol, add the server IP to `MTX_WEBRTCADDITIONALHOSTS` and expose ports manually:

```
docker run --rm -it \
-e MTX_RTSPTRANSPORTS=tcp \
-e MTX_WEBRTCADDITIONALHOSTS=192.168.x.x \
-p 8554:8554 \
-p 1935:1935 \
-p 8888:8888 \
-p 8889:8889 \
-p 8890:8890/udp \
-p 8189:8189/udp \
bluenviron/mediamtx
```