# Stage 1: Install FFmpeg in a compatible builder environment
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y ffmpeg jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 2: Final n8n image
FROM n8nio/n8n:latest

USER root

# Copy FFmpeg and jq from the builder
COPY --from=builder /usr/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=builder /usr/bin/ffprobe /usr/bin/ffprobe
COPY --from=builder /usr/bin/jq /usr/bin/jq

# Copy necessary shared libraries for FFmpeg to run
# COPY --from=builder /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
# COPY --from=builder /lib/x86_64-linux-gnu /lib/x86_64-linux-gnu

# If you are on Mac M3 (ARM), use these paths instead (Uncomment if the above fails):
COPY --from=builder /usr/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu
COPY --from=builder /lib/aarch64-linux-gnu /lib/aarch64-linux-gnu

USER node
