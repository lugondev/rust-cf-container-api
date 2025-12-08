# Rust Cloudflare Container API

A high-performance API service built with Rust (Actix-web) running in Cloudflare Workers Containers, orchestrated by a TypeScript Worker using Hono.

## Overview

This project demonstrates how to run a Rust-based HTTP server as a container on Cloudflare's edge network. It combines:

- **Rust Container**: Actix-web server providing REST API endpoints
- **TypeScript Worker**: Hono-based router for request orchestration and load balancing
- **Cloudflare Containers**: Deploy and scale containerized workloads at the edge

## Features

- ✅ Health check and status endpoints
- ✅ External API integration (IP information fetching)
- ✅ Container lifecycle management (start, stop, error handling)
- ✅ Load balancing across multiple container instances
- ✅ Singleton and multi-instance routing patterns
- ✅ Automatic container sleep after 2 minutes of inactivity

## Getting Started

### Prerequisites

- Node.js 18+ and pnpm
- Rust toolchain (for local container development)
- Cloudflare account with Workers enabled
- Docker (for containerization)

### Installation

Install dependencies:

```bash
pnpm install
```

### Development

Run the development server:

```bash
pnpm run dev
```

OpeAPI Endpoints

### Worker Routes (Port 8787)

- `GET /` - List all available endpoints
- `GET /container/:id` - Route to a specific container instance by ID
- `GET /lb` - Load-balanced request across 3 container instances
- `GET /singleton` - Route to a single shared container instance
- `GET /error` - Demonstrate error handling
- `GET /api/*` - Forward requests to container API

### Container API Routes (Port 8080)

- `GET /` - Welcome message
- `GET /api/` - API documentation (JSON)
- `GET /api/health` - Health check endpoint
- `GET /api/ping` - Simple ping-pong test
- `GET /api/ip` - Fetch IP information from ipinfo.io

## Configuration

### Container Settings

Configured in `src/index.ts` via the `MyContainer` class:

```typescript
defaultPort = 8080;           // Container listening port
sleepAfter = "2m";           // Inactivity timeout
envVars = { ... };           // Environment variables
```

### Cloudflare Configuration

See `wrangler.jsonc`:

- `max_instances: 10` - Maximum concurrent containers
- Container image built from `./Dockerfile`
- Durable Objects binding for container orchestration

## Deploying To Production

Deploy to Cloudflare:

```bash
pnpm run deploy
```

This will:
1. Build the Rust container image
2. Upload the TypeScript Worker
3. Deploy to Cloudflare's global network

## Tech Stack

- **Container**: Rust + Actix-web + Reqwest
- **Worker**: TypeScript + Hono
- **Platform**: Cloudflare Workers + Containers + Durable Objects

## Learn More

- [Cloudflare Containers Documentation](https://developers.cloudflare.com/containers/)
- [Container Helper Class](https://github.com/cloudflare/containers)
- [Actix-web Documentation](https://actix.rs/)
- [Hono Framework](https://hono.dev/)
### Project Structure

- `src/index.ts` - TypeScript Worker (Hono router and container orchestration)
- `container/src/main.rs` - Rust container (Actix-web API server)
- `Dockerfile` - Container image configuration
- `wrangler.jsonc` - Cloudflare Workers configuration

## Deploying To Production

| Command          | Action                                |
| :--------------- | :------------------------------------ |
| `npm run deploy` | Deploy your application to Cloudflare |

## Learn More

To learn more about Containers, take a look at the following resources:

- [Container Documentation](https://developers.cloudflare.com/containers/) - learn about Containers
- [Container Class](https://github.com/cloudflare/containers) - learn about the Container helper class

Your feedback and contributions are welcome!
