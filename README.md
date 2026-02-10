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

### 1. Fork & Deploy

```bash
# Fork this repo, then:
git clone https://github.com/YOUR_USERNAME/supabase-railway.git
cd supabase-railway
railway link
```

### 2. Generate Secrets

```bash
# Generate a JWT secret (minimum 32 characters)
openssl rand -hex 32

# Generate ANON_KEY (replace YOUR_JWT_SECRET)
node -e "
const crypto = require('crypto');
const secret = 'YOUR_JWT_SECRET';
const header = Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');
const payload = Buffer.from(JSON.stringify({role:'anon',iss:'supabase',iat:1700000000,exp:2000000000})).toString('base64url');
const sig = crypto.createHmac('sha256',secret).update(header+'.'+payload).digest('base64url');
console.log('ANON_KEY=' + header+'.'+payload+'.'+sig);
"

# Generate SERVICE_ROLE_KEY (replace YOUR_JWT_SECRET)
node -e "
const crypto = require('crypto');
const secret = 'YOUR_JWT_SECRET';
const header = Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');
const payload = Buffer.from(JSON.stringify({role:'service_role',iss:'supabase',iat:1700000000,exp:2000000000})).toString('base64url');
const sig = crypto.createHmac('sha256',secret).update(header+'.'+payload).digest('base64url');
console.log('SERVICE_ROLE_KEY=' + header+'.'+payload+'.'+sig);
"

# Generate Studio password hash
docker run --rm caddy caddy hash-password --plaintext 'YourSecurePassword'
```

### 3. Set Environment Variables

Set these on each Railway service via the dashboard or CLI.

#### Shared (all services that validate JWTs)
| Variable | Description |
|----------|-------------|
| `PGRST_JWT_SECRET` | Your JWT secret (hex, 32+ chars) |
| `ANON_KEY` | JWT signed with `role: anon` |
| `SERVICE_KEY` | JWT signed with `role: service_role` |

#### Database (`supabase-db`)
| Variable | Description |
|----------|-------------|
| `POSTGRES_PASSWORD` | Database password |
| `POSTGRES_DB` | `postgres` |

#### Gateway (`supabase-gateway`)
| Variable | Description |
|----------|-------------|
| `CORS_ORIGIN` | Allowed origin (default: `*`) |

#### Auth (`supabase-auth`)
| Variable | Description |
|----------|-------------|
| `API_EXTERNAL_URL` | **Must be gateway URL** |
| `GOTRUE_SITE_URL` | **Must be gateway URL** |
| `GOTRUE_JWT_SECRET` | Same as `PGRST_JWT_SECRET` |
| `GOTRUE_DB_DATABASE_URL` | Postgres connection string |

#### Studio (`supabase-studio`)
| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | **Must be gateway URL** (not PostgREST!) |
| `SUPABASE_PUBLIC_URL` | **Must be gateway URL** |
| `STUDIO_PG_META_URL` | Internal meta service URL |
| `STUDIO_USERNAME` | Basic auth username (default: `admin`) |
| `STUDIO_PASSWORD_HASH` | Bcrypt hash (from `caddy hash-password`) |

#### Storage (`supabase-storage`)
| Variable | Description |
|----------|-------------|
| `ANON_KEY` | Must be signed with the shared JWT secret |
| `SERVICE_KEY` | Must be signed with the shared JWT secret |

### 4. Connect Your App

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://YOUR-GATEWAY.up.railway.app',
  'YOUR_ANON_KEY'
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

Studio is protected with HTTP Basic Auth via a Caddy sidecar. To set it up:

```bash
# 1. Generate a bcrypt password hash
docker run --rm caddy caddy hash-password --plaintext 'YourSecurePassword'
# Output: $2a$14$Zkq6...

# 2. Set environment variables on supabase-studio service
railway variables set STUDIO_USERNAME=admin -s supabase-studio
railway variables set STUDIO_PASSWORD_HASH='$2a$14$Zkq6...' -s supabase-studio

# 3. Redeploy Studio
railway up -s supabase-studio
```

When you visit Studio, the browser will prompt for username/password.

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
|   +-- Dockerfile      # Studio + Caddy auth sidecar
|   +-- Caddyfile       # Basic auth config
|   +-- start.sh        # Starts both Studio and Caddy
|   +-- railway.toml
+-- edge-functions/     # Deno Edge Runtime
|   +-- Dockerfile
|   +-- railway.toml
|   +-- functions/      # Your functions here
+-- imgproxy/           # Image transformations
|   +-- Dockerfile
|   +-- railway.toml
```

Services from Docker images (no source directory):
- `supabase-rest` (postgrest/postgrest:v12.2.3)
- `supabase-auth` (supabase/gotrue:v2.168.0)
- `supabase-storage` (supabase/storage-api:v1.14.5)
- `supabase-realtime` (supabase/realtime:v2.33.70)
- `supabase-meta` (supabase/postgres-meta:v0.84.2)
- `supabase-minio` (minio/minio:latest)

## Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Storage "invalid signature" | JWT keys not signed with shared secret | Regenerate ANON_KEY/SERVICE_KEY with correct PGRST_JWT_SECRET |
| "Failed to fetch buckets" in Studio | SUPABASE_URL points to PostgREST | Set SUPABASE_URL to the **gateway** URL |
| CORS: duplicate Access-Control-Allow-Origin | Upstream + gateway both add headers | Gateway strips upstream CORS via `header_down` |
| Auth redirects to dead URL | API_EXTERNAL_URL points to old Kong | Set API_EXTERNAL_URL to the **gateway** URL |
| Gateway deploy fails silently | Deployed from subdirectory | Deploy from **repo root** (`railway up -s supabase-gateway`) |
| Caddy won't start | Invalid Caddyfile syntax | Check logs; `basic_auth` needs to be `basicauth` in Caddy 2 |

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
