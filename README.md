# Supabase on Railway

A complete, production-ready self-hosted Supabase deployment on Railway with 11 services, Caddy API gateway, and password-protected Studio dashboard.

## Architecture

```
                     Internet
                        |
    +-------------------+-------------------+
    |                                       |
    v                                       v
[Gateway - Caddy :8080]              [Studio - Caddy+Next.js :3000]
    |                                (password protected)
    +-- /auth/v1/*     --> Auth (GoTrue)
    +-- /rest/v1/*     --> REST (PostgREST)
    +-- /storage/v1/*  --> Storage API
    +-- /functions/v1/* -> Edge Functions (Deno)
    +-- /realtime/v1/* --> Realtime
    |
    +-- [Internal Services]
        +-- PostgreSQL (with Supabase extensions)
        +-- MinIO (S3-compatible object storage)
        +-- postgres-meta (database metadata API)
        +-- imgproxy (image transformations, sleeps when idle)
```

## Services

| Service | Image / Source | Port | Description |
|---------|---------------|------|-------------|
| **supabase-db** | Custom Postgres 15 | 5432 | Database with Supabase extensions |
| **supabase-gateway** | Caddy 2.7-alpine | 8080 | API gateway / reverse proxy |
| **supabase-rest** | postgrest/postgrest:v12.2.3 | 3000 | RESTful API for Postgres |
| **supabase-auth** | supabase/gotrue:v2.168.0 | 9999 | Authentication & authorization |
| **supabase-storage** | supabase/storage-api:v1.14.5 | 5000 | File storage backed by MinIO |
| **supabase-realtime** | supabase/realtime:v2.33.70 | 4000 | WebSocket subscriptions |
| **supabase-studio** | supabase/studio + Caddy auth | 3000 | Dashboard UI (password protected) |
| **supabase-meta** | supabase/postgres-meta:v0.84.2 | 8080 | Database metadata for Studio |
| **supabase-minio** | minio/minio:latest | 9000 | S3-compatible object storage |
| **supabase-edge-functions** | Custom Deno runtime | 9000 | Serverless edge functions |
| **supabase-imgproxy** | Custom imgproxy | 8080 | Image resizing/transforms |

## Quick Start

### Deploy from Template

Click the button below to deploy the full Supabase stack to Railway. All environment variables, internal networking, and service connections are configured automatically — no manual setup required.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/YOUR_TEMPLATE_ID)

Once deployed, you'll have:
- A **Gateway URL** — this is your Supabase API endpoint (use it in your app)
- A **Studio URL** — the Supabase dashboard (password protected)

### Connect Your App

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://YOUR-GATEWAY.up.railway.app',
  'YOUR_ANON_KEY'  // found in supabase-rest service variables
)

// Auth
const { data } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123'
})

// Database
const { data: rows } = await supabase
  .from('your_table')
  .select('*')

// Storage
const { data: file } = await supabase.storage
  .from('your-bucket')
  .upload('path/file.png', fileBody)
```

## Studio Password Protection

Studio is protected with HTTP Basic Auth via a Caddy sidecar. When you visit Studio, the browser will prompt for username and password.

**Default credentials:**
- **Username:** `admin`
- **Password:** `123456`

> **Change these in production!** See below.

### Changing the Studio Password

```bash
# 1. Generate a new bcrypt password hash
#    Option A: Using Docker
docker run --rm caddy caddy hash-password --plaintext 'YourNewSecurePassword'

#    Option B: Using Python
python -c "import bcrypt; print(bcrypt.hashpw(b'YourNewSecurePassword', bcrypt.gensalt(rounds=14)).decode())"

#    Option C: Using an online bcrypt generator (use cost factor 14)

# 2. Set the new credentials on supabase-studio service
railway variables set STUDIO_USERNAME=your_username -s supabase-studio
railway variables set STUDIO_PASSWORD_HASH='$2b$14$YOUR_NEW_HASH_HERE' -s supabase-studio

# 3. Redeploy Studio
railway up -s supabase-studio
```

If you don't set `STUDIO_USERNAME` or `STUDIO_PASSWORD_HASH` as env vars, the defaults (`admin` / `123456`) are used. Setting the env vars overrides the defaults.

## API Endpoints

All endpoints are available through the gateway:

| Path | Service | Description |
|------|---------|-------------|
| `/auth/v1/*` | GoTrue | Authentication (signup, login, OAuth) |
| `/rest/v1/*` | PostgREST | Database REST API |
| `/storage/v1/*` | Storage | File upload/download |
| `/functions/v1/*` | Edge Functions | Serverless functions |
| `/realtime/v1/*` | Realtime | WebSocket subscriptions |
| `/health` | Gateway | Health check |

```bash
# Test gateway
curl https://YOUR-GATEWAY.up.railway.app/health

# Test auth
curl https://YOUR-GATEWAY.up.railway.app/auth/v1/settings

# Test REST (with API key)
curl https://YOUR-GATEWAY.up.railway.app/rest/v1/ \
  -H "apikey: YOUR_ANON_KEY"

# Test edge function
curl https://YOUR-GATEWAY.up.railway.app/functions/v1/hello
```

## Gateway Configuration

The gateway uses Caddy to reverse-proxy all Supabase services. Key design decisions:

1. **CORS handled centrally** - Gateway sets CORS headers and strips duplicates from upstream services
2. **TLS to upstream** - All internal Railway service-to-service calls use TLS
3. **Health check** - `/health` endpoint for Railway's deployment health checks

See `gateway/Caddyfile` for the full configuration.

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

Available functions: `hello`, `db-test`, `echo`

See [EDGE-FUNCTIONS-GUIDE.md](./EDGE-FUNCTIONS-GUIDE.md) for more.

## Deployment

```bash
# Deploy a specific service
railway up -s supabase-gateway

# IMPORTANT: Always deploy from the repo root, not from subdirectories.
# Each service has rootDirectory configured on Railway (e.g., gateway/).
```

## Folder Structure

```
supabase-railway/
+-- postgres/           # PostgreSQL 15 with Supabase extensions
|   +-- Dockerfile
|   +-- railway.toml
|   +-- *.sql           # Init scripts (roles, webhooks, JWT)
+-- gateway/            # Caddy API gateway
|   +-- Dockerfile
|   +-- Caddyfile       # Reverse proxy + CORS config
|   +-- railway.toml
+-- studio/             # Supabase Dashboard (password protected)
|   +-- Dockerfile      # Multi-stage: Studio + Caddy binary
|   +-- start.sh        # Starts Caddy auth proxy + Studio
|   +-- railway.toml
+-- edge-functions/     # Deno Edge Runtime
|   +-- Dockerfile
|   +-- railway.toml
|   +-- functions/      # Your functions here
+-- imgproxy/           # Image transformations
|   +-- Dockerfile
|   +-- railway.toml
+-- brand-assets/       # Supabase logos (icon, wordmark light/dark)
```

Services from Docker images (no source directory):
- `supabase-rest` (postgrest/postgrest:v12.2.3)
- `supabase-auth` (supabase/gotrue:v2.168.0)
- `supabase-storage` (supabase/storage-api:v1.14.5)
- `supabase-realtime` (supabase/realtime:v2.33.70)
- `supabase-meta` (supabase/postgres-meta:v0.84.2)
- `supabase-minio` (minio/minio:latest)

## Environment Variables Reference

All variables are **pre-configured by the Railway template**. You don't need to set anything manually for a working deployment. This section is for reference only if you need to customize or debug.

<details>
<summary>Click to expand full variable reference</summary>

#### Shared (all services that validate JWTs)
| Variable | Description |
|----------|-------------|
| `PGRST_JWT_SECRET` | JWT secret (auto-generated) |
| `ANON_KEY` | JWT signed with `role: anon` |
| `SERVICE_KEY` | JWT signed with `role: service_role` |

#### Database (`supabase-db`)
| Variable | Description |
|----------|-------------|
| `POSTGRES_PASSWORD` | Database password (auto-generated) |
| `POSTGRES_DB` | `postgres` |

#### Auth (`supabase-auth`)
| Variable | Description |
|----------|-------------|
| `API_EXTERNAL_URL` | Gateway URL (auto-wired) |
| `GOTRUE_SITE_URL` | Gateway URL (auto-wired) |
| `GOTRUE_JWT_SECRET` | Same as `PGRST_JWT_SECRET` |
| `GOTRUE_DB_DATABASE_URL` | Postgres connection string (auto-wired) |

#### Studio (`supabase-studio`)
| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Gateway URL (auto-wired) |
| `SUPABASE_PUBLIC_URL` | Gateway URL (auto-wired) |
| `STUDIO_PG_META_URL` | Internal meta service URL (auto-wired) |
| `STUDIO_USERNAME` | Basic auth username (default: `admin`) |
| `STUDIO_PASSWORD_HASH` | Bcrypt hash (default: hash of `123456`) |

#### Storage (`supabase-storage`)
| Variable | Description |
|----------|-------------|
| `ANON_KEY` | Signed with the shared JWT secret |
| `SERVICE_KEY` | Signed with the shared JWT secret |

</details>

## Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Storage "invalid signature" | JWT keys not signed with shared secret | Regenerate ANON_KEY/SERVICE_KEY with correct PGRST_JWT_SECRET |
| "Failed to fetch buckets" in Studio | SUPABASE_URL points to PostgREST | Set SUPABASE_URL to the **gateway** URL |
| CORS: duplicate Access-Control-Allow-Origin | Upstream + gateway both add headers | Gateway strips upstream CORS via `header_down` |
| Auth redirects to dead URL | API_EXTERNAL_URL points to old Kong | Set API_EXTERNAL_URL to the **gateway** URL |
| Gateway deploy fails silently | Deployed from subdirectory | Deploy from **repo root** (`railway up -s supabase-gateway`) |

## Security

See [SECURITY-GUIDE.md](./SECURITY-GUIDE.md) for:
- Studio access protection
- CORS configuration
- RLS setup
- Secret rotation
- Emergency response

## Credits

Based on [6ixfalls/supabase](https://github.com/6ixfalls/supabase), enhanced with:
- Caddy gateway replacing Kong
- Password-protected Studio
- Edge Functions support
- CORS deduplication
- Railway template optimizations

## License

MIT
