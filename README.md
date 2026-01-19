# Supabase on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/supabase)

A complete, self-hosted Supabase deployment for Railway with all core services.

## Services Included

| Service | Description | Port |
|---------|-------------|------|
| **postgres** | PostgreSQL 15 with Supabase extensions | 5432 |
| **gateway** | Caddy reverse proxy (API gateway) | 8080 |
| **studio** | Supabase Dashboard UI | 3000 |
| **edge-functions** | Deno Edge Runtime | 9000 |
| **imgproxy** | Image transformation service | 8080 |

## Quick Start

### 1. Deploy to Railway

Click the button above or manually:

1. Fork this repository
2. Create a new Railway project
3. Add services from the repo (one per folder)
4. Configure environment variables
5. Deploy

### 2. Required Environment Variables

Set these in Railway for each service:

#### All Services
```
JWT_SECRET=your-super-secret-jwt-token-min-32-chars
ANON_KEY=your-anon-key
SERVICE_ROLE_KEY=your-service-role-key
```

#### Database (postgres)
```
POSTGRES_PASSWORD=your-secure-password
POSTGRES_DB=postgres
```

#### Gateway
```
CORS_ORIGIN=https://your-frontend.com
```

### 3. Generate API Keys

Use the Supabase key generator or:

```bash
# Generate JWT secret
openssl rand -base64 32

# Generate keys using supabase CLI
supabase gen keys
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Internet                           │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Gateway (Caddy)                        │
│              supabase-gateway.railway.app               │
└─────────────────────────┬───────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│    Studio     │ │ Edge Functions│ │   ImgProxy    │
│   /studio/*   │ │ /functions/*  │ │  /imgproxy/*  │
└───────────────┘ └───────────────┘ └───────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 PostgreSQL Database                     │
│                    (postgres)                           │
└─────────────────────────────────────────────────────────┘
```

## API Endpoints

All endpoints are available through the gateway:

| Endpoint | Description |
|----------|-------------|
| `/rest/v1/*` | PostgREST API |
| `/auth/v1/*` | GoTrue Authentication |
| `/storage/v1/*` | Storage API |
| `/functions/v1/*` | Edge Functions |
| `/realtime/v1/*` | Realtime WebSocket |
| `/studio/*` | Dashboard (protected) |

## Security

**Important:** Studio is protected with basic auth.

Default credentials (change in production!):
- **Username:** `jude`
- **Password:** `143668`

To change credentials, update `gateway/Caddyfile` and generate a new bcrypt hash:

```bash
docker run --rm caddy caddy hash-password --plaintext 'YourNewPassword'
```

See [SECURITY-GUIDE.md](./SECURITY-GUIDE.md) for complete security configuration.

## Edge Functions

Create serverless functions in `edge-functions/functions/`:

```typescript
// edge-functions/functions/my-function/index.ts
Deno.serve(async (req: Request) => {
  return new Response(
    JSON.stringify({ message: "Hello from Edge!" }),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

See [EDGE-FUNCTIONS-GUIDE.md](./EDGE-FUNCTIONS-GUIDE.md) for complete documentation.

## Folder Structure

```
supabase-railway/
├── postgres/           # PostgreSQL with Supabase extensions
│   ├── Dockerfile
│   ├── railway.toml
│   └── *.sql          # Init scripts
├── gateway/            # Caddy reverse proxy
│   ├── Dockerfile
│   ├── Caddyfile
│   └── railway.toml
├── studio/             # Supabase Dashboard
│   ├── Dockerfile
│   └── railway.toml
├── edge-functions/     # Deno Edge Runtime
│   ├── Dockerfile
│   ├── railway.toml
│   └── functions/     # Your functions here
└── imgproxy/           # Image transformations
    ├── Dockerfile
    └── railway.toml
```

## Troubleshooting

### Database not starting
- Check volume is attached
- Verify `POSTGRES_PASSWORD` is set

### Studio not loading
- Ensure gateway is running
- Check `/studio/*` route in Caddyfile

### Edge functions 404
- Verify function exists in `functions/` folder
- Check main router in `functions/main/index.ts`

## Credits

Based on work by [6ixfalls](https://github.com/6ixfalls/supabase) and enhanced with:
- Caddy gateway (replacing Kong)
- Edge Functions support
- Security hardening
- Railway template optimizations

## License

MIT License

---

Built with Supabase and Railway
