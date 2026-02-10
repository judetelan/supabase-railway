# Supabase Railway - API Endpoints

## Gateway (Unified Entry Point)

**URL:** `https://YOUR-GATEWAY.up.railway.app`

All Supabase services are accessible through the gateway:

| Path | Service | Description |
|------|---------|-------------|
| `/rest/v1/*` | PostgREST | Database REST API |
| `/auth/v1/*` | GoTrue | Authentication |
| `/storage/v1/*` | Storage | File storage |
| `/functions/v1/*` | Edge Functions | Serverless functions |
| `/realtime/v1/*` | Realtime | WebSocket subscriptions |
| `/health` | Gateway | Health check |

## Using with Supabase JS Client

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://YOUR-GATEWAY.up.railway.app',
  'YOUR_ANON_KEY'
)
```

## Quick Test Commands

```bash
# Health check
curl https://YOUR-GATEWAY.up.railway.app/health

# Auth settings
curl https://YOUR-GATEWAY.up.railway.app/auth/v1/settings

# REST API (Swagger spec)
curl https://YOUR-GATEWAY.up.railway.app/rest/v1/ \
  -H "apikey: YOUR_ANON_KEY"

# Storage (list buckets, requires service role key)
curl https://YOUR-GATEWAY.up.railway.app/storage/v1/bucket \
  -H "apikey: YOUR_SERVICE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_KEY"

# Edge function
curl https://YOUR-GATEWAY.up.railway.app/functions/v1/hello

# Sign up a user
curl -X POST https://YOUR-GATEWAY.up.railway.app/auth/v1/signup \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{"email":"user@example.com","password":"password123"}'
```

## Edge Functions

Available functions:
- `hello` - Hello world test
- `db-test` - Database connectivity test
- `echo` - Request echo/debugging

```bash
curl https://YOUR-GATEWAY.up.railway.app/functions/v1/hello
curl https://YOUR-GATEWAY.up.railway.app/functions/v1/db-test
curl https://YOUR-GATEWAY.up.railway.app/functions/v1/echo -d '{"test": "data"}'
```

## Direct Service URLs

> **Note:** For most use cases, use the gateway URL. Direct service URLs are for debugging only.

Each service has its own Railway domain. Find them in your Railway dashboard under each service's Settings > Networking.

## Database Connection

Find your database credentials in Railway's environment variables for the `supabase-db` service:
- Host: `supabase-db.railway.internal` (internal) or the public Railway domain
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: Set via `POSTGRES_PASSWORD` env var

> **Never commit database credentials to git.** Use Railway's environment variables UI.
