# docker build . -f docker/ffmpeg.nvidia.Dockerfile -t oxymoron0/mediamtx:nvidia-ffmpeg

ARG CUDA_VERSION="12.9.0"
ARG UBUNTU_VERSION="24.04"
ARG DEBIAN_VERSION="bookworm-slim"

#################################################################
FROM --platform=linux/amd64 scratch AS binaries

ADD binaries/mediamtx_*_linux_amd64.tar.gz /linux/amd64
ADD binaries/mediamtx_*_linux_armv6.tar.gz /linux/arm/v6
ADD binaries/mediamtx_*_linux_armv7.tar.gz /linux/arm/v7
ADD binaries/mediamtx_*_linux_arm64.tar.gz /linux/arm64
#################################################################

FROM nvidia/cuda:${CUDA_VERSION}-cudnn-devel-ubuntu${UBUNTU_VERSION} AS ffmpeg-builder
ENV TZ=${BUILD_HOST_TZ:-Asia/Seoul}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y \
    build-essential \
    git \
    nasm \
    yasm \
    cmake \
    libx264-dev \
    libx265-dev \
    libnuma-dev \
    libtool-bin \
    pkg-config

# Install NV-Codec-Headers
RUN git clone https://github.com/FFmpeg/nv-codec-headers.git /usr/src/nv-codec-headers && \
    cd /usr/src/nv-codec-headers && \
    make install

# Build Configure 
RUN git clone https://git.ffmpeg.org/ffmpeg.git /usr/src/ffmpeg && \
    cd /usr/src/ffmpeg && \
    ./configure \
    --prefix="/usr/local/ffmpeg_cuda" \
    --enable-gpl \
    --enable-shared \
    --enable-nonfree \
    --enable-nvenc \
    --enable-nvdec \
    --enable-cuda-nvcc \
    --enable-cuvid \
    --enable-libx264 \
    --enable-libx265 \
    --extra-cflags="-I/usr/local/cuda/include -I/usr/local/include/ffnvcodec" \
    --extra-ldflags="-L/usr/local/cuda/lib64" \
    --disable-static && \
    make -j$(nproc) && \
    make install

#################################################################
FROM debian:${DEBIAN_VERSION}
ENV TZ=${BUILD_HOST_TZ:-Asia/Seoul}
ENV DEBIAN_FRONTEND=noninteractive

# Prepare apt for buildkit cache
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
  && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache
  
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo 'deb http://deb.debian.org/debian trixie non-free' > /etc/apt/sources.list.d/debian-non-free.list && \
    apt-get -y update && apt-get -y install \
        libx264-dev \
        libx265-dev
    apt-get clean && rm -rf /var/lib/apt/lists/*

ARG TARGETPLATFORM
COPY --from=binaries /$TARGETPLATFORM /
COPY --from=ffmpeg-builder /usr/local/ffmpeg_cuda /usr/local/ffmpeg_cuda

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,video,utility
ENV PATH="/usr/local/ffmpeg_cuda/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/ffmpeg_cuda/lib:$LD_LIBRARY_PATH"

ENTRYPOINT [ "/mediamtx" ]
