# Supabase Railway

Self-hosted Supabase components for Railway deployment. Based on [6ixfalls/supabase](https://github.com/6ixfalls/supabase).

## Components

### Kong API Gateway (`/kong`)
- Routes traffic to all Supabase services
- Handles authentication via API keys
- Basic auth for dashboard access

### PostgreSQL Database (`/postgres`)
- Custom Supabase Postgres image with init scripts
- Sets up required schemas: `_realtime`, `_analytics`, `_supavisor`
- Configures roles and permissions

## Required Environment Variables

### Kong
| Variable | Description |
|----------|-------------|
| `SUPABASE_ANON_KEY` | Anon JWT key |
| `SUPABASE_SERVICE_KEY` | Service role JWT key |
| `DASHBOARD_USERNAME` | Studio basic auth username |
| `DASHBOARD_PASSWORD` | Studio basic auth password |
| `AUTH_HOST` | Auth service hostname |
| `REST_HOST` | PostgREST hostname |
| `REALTIME_HOST` | Realtime service hostname |
| `STORAGE_HOST` | Storage service hostname |
| `META_HOST` | Postgres Meta hostname |
| `STUDIO_HOST` | Studio hostname |
| `ANALYTICS_HOST` | Analytics hostname |

### PostgreSQL
| Variable | Description |
|----------|-------------|
| `POSTGRES_USER` | Database admin user |
| `POSTGRES_PASSWORD` | Database password |
| `JWT_SECRET` | JWT secret for auth |
| `JWT_EXP` | JWT expiration time |

## Limitations

Edge Functions require separate deployment of `ghcr.io/supabase/edge-runtime`.

## Credits

Based on the Railway Supabase template by [6ixfalls](https://github.com/6ixfalls/supabase).
