# Tools to turn the Figma stroke icons into VLC's icon font.
FROM debian:trixie-slim
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      inkscape python3-fontforge python3-jsonschema \
 && rm -rf /var/lib/apt/lists/*
