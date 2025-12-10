# syntax=docker/dockerfile:1

#
# ---- Planner Stage ----
#
# Using Debian-based Rust image
ARG TARGETPLATFORM=linux/amd64

FROM rust:1-slim-bookworm AS planner

# Install cargo-chef
RUN cargo install cargo-chef

WORKDIR /app

# Copy all source files to prepare the recipe
COPY container/ ./

# Generate the recipe file
RUN cargo chef prepare --recipe-path recipe.json

#
# ---- Dependency Builder Stage ----
#
# Using Debian Bookworm-based Rust image
FROM rust:1-slim-bookworm AS dependencies

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-chef
RUN cargo install cargo-chef

# Download and install pre-built sccache binary
RUN curl -Lo sccache.tar.gz https://github.com/mozilla/sccache/releases/download/v0.8.2/sccache-v0.8.2-x86_64-unknown-linux-musl.tar.gz && \
    tar xzf sccache.tar.gz && \
    mv sccache-v0.8.2-x86_64-unknown-linux-musl/sccache /usr/local/bin/ && \
    chmod +x /usr/local/bin/sccache && \
    rm -rf sccache.tar.gz sccache-v0.8.2-x86_64-unknown-linux-musl

# Configure sccache
ENV RUSTC_WRAPPER=/usr/local/bin/sccache \
    SCCACHE_DIR=/sccache \
    CARGO_INCREMENTAL=0

WORKDIR /app

# Copy the recipe from planner stage and full workspace structure for local dependencies
COPY --from=planner /app/recipe.json recipe.json
COPY --from=planner /app/Cargo.toml Cargo.toml
COPY --from=planner /app/src src

# Build dependencies only - this layer will be cached
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/sccache \
    cargo chef cook --release --recipe-path recipe.json && \
    sccache --show-stats

#
# ---- Builder Stage ----
#
# Using Debian Bookworm-based Rust image
FROM rust:1-slim-bookworm AS build

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download and install pre-built sccache binary
RUN curl -Lo sccache.tar.gz https://github.com/mozilla/sccache/releases/download/v0.8.2/sccache-v0.8.2-x86_64-unknown-linux-musl.tar.gz && \
    tar xzf sccache.tar.gz && \
    mv sccache-v0.8.2-x86_64-unknown-linux-musl/sccache /usr/local/bin/ && \
    chmod +x /usr/local/bin/sccache && \
    rm -rf sccache.tar.gz sccache-v0.8.2-x86_64-unknown-linux-musl

# Configure sccache
ENV RUSTC_WRAPPER=/usr/local/bin/sccache \
    SCCACHE_DIR=/sccache \
    CARGO_INCREMENTAL=0

WORKDIR /app

# Copy the built dependencies from dependencies stage
COPY --from=dependencies /app/target target
COPY --from=dependencies /usr/local/cargo /usr/local/cargo

# Copy the actual source code
COPY container/ ./

# Build the final application
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/sccache \
    cargo build --release && \
    sccache --show-stats

#
# ---- Final Stage ----
#
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the built binary
COPY --from=build /app/target/release/server /usr/local/bin/server

# Expose the port the application will listen on
EXPOSE 8080

# Set the entrypoint
CMD ["server"]
