# Supabase Edge Functions - Self-Hosted on Railway

> **Reference**: https://supabase.com/docs/guides/self-hosting/docker#accessing-your-edge-functions

## Why Studio Doesn't Work

The Supabase Studio dashboard **cannot create/manage edge functions in self-hosted deployments** because:
- Studio's edge function UI requires Supabase cloud backend services
- Self-hosted uses filesystem-based function discovery
- No CLI support for deploying to self-hosted instances

**Solution**: Manage functions via filesystem + Git + Railway redeploy.

---

## Current Directory Structure

```
supabase-railway/edge-functions/
├── Dockerfile
└── functions/
    ├── main/           # Router (delegates to other functions)
    │   └── index.ts
    ├── hello/          # Example function
    │   └── index.ts
    ├── db-test/        # Database connectivity test
    │   └── index.ts
    └── echo/           # Returns request details
        └── index.ts
```

---

## How to Add a New Edge Function

### Step 1: Create Function Directory

```bash
mkdir supabase-railway/edge-functions/functions/my-function
```

### Step 2: Create index.ts with `Deno.serve()`

```typescript
// functions/my-function/index.ts

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { name } = await req.json().catch(() => ({ name: "World" }));

    return new Response(
      JSON.stringify({
        message: `Hello ${name}!`,
        timestamp: new Date().toISOString()
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
```

### Step 3: Deploy

```bash
cd supabase-railway
git add .
git commit -m "Add my-function edge function"
git push origin main
```

Railway will automatically redeploy. Your function is available at:
```
https://your-gateway.up.railway.app/functions/v1/my-function
```

---

## How It Works

1. **Gateway (Caddy)** receives request at `/functions/v1/{name}`
2. **Caddy** routes to edge-functions service on port 9000
3. **Main worker** extracts function name from path
4. **Main worker** creates a user worker for that function using `EdgeRuntime.userWorkers.create()`
5. **User worker** executes the function in an isolated V8 context

```
Client → Gateway → Edge Runtime → Main Worker → User Worker (your function)
```

---

## Available Environment Variables

Automatically available in your functions:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Gateway URL for API calls |
| `SUPABASE_ANON_KEY` | Anonymous API key |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (full access) |
| `SUPABASE_DB_URL` | Direct PostgreSQL connection string |
| `JWT_SECRET` | JWT signing secret |

### Using in Functions

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data, error } = await supabase
    .from("your_table")
    .select("*");

  return new Response(JSON.stringify({ data, error }), {
    headers: { "Content-Type": "application/json" }
  });
});
```

---

## Function Templates

### Basic Function

```typescript
Deno.serve(async (req: Request) => {
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" }
  });
});
```

### With Database Query

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data, error } = await supabase
    .from("users")
    .select("id, name, email")
    .limit(10);

  return new Response(JSON.stringify({ data, error }));
});
```

### With External API Call

```typescript
Deno.serve(async (req: Request) => {
  const response = await fetch("https://api.example.com/data", {
    headers: { "Authorization": `Bearer ${Deno.env.get("API_KEY")}` }
  });

  const data = await response.json();
  return new Response(JSON.stringify(data));
});
```

### With Request Body

```typescript
Deno.serve(async (req: Request) => {
  const body = await req.json();

  // Process body...
  const result = { received: body, processed: true };

  return new Response(JSON.stringify(result));
});
```

---

## Testing Your Functions

### Test hello function
```bash
curl -X POST https://supabase-gateway-production-XXXX.up.railway.app/functions/v1/hello \
  -H "Content-Type: application/json" \
  -d '{"name": "Railway"}'
```

### Test db-test function
```bash
curl https://supabase-gateway-production-XXXX.up.railway.app/functions/v1/db-test
```

### Test echo function
```bash
curl -X POST https://supabase-gateway-production-XXXX.up.railway.app/functions/v1/echo \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### Health check
```bash
curl https://supabase-gateway-production-XXXX.up.railway.app/functions/v1/
```

---

## Debugging

### View edge-functions logs
```bash
railway logs -s supabase-edge-functions
```

### Check if service is running
```bash
curl https://your-gateway.up.railway.app/functions/v1/
```

---

## Limitations & Workarounds

| Limitation | Workaround |
|------------|------------|
| No Studio UI for functions | Filesystem + Git deployment |
| No `supabase functions deploy` CLI | Git push triggers Railway redeploy |
| No nested directories | Flat structure with naming prefixes |
| No scheduled functions | External cron calling HTTP endpoints |
| Memory limit 150MB | Keep functions lightweight |
| Timeout 60 seconds | Offload long tasks to background jobs |

---

## Quick Reference

| Action | How |
|--------|-----|
| Add function | Create `functions/{name}/index.ts` with `Deno.serve()` |
| Deploy | `git push` to Railway |
| Test | `curl https://gateway/functions/v1/{name}` |
| View logs | `railway logs -s supabase-edge-functions` |
| Set env vars | Railway dashboard → edge-functions → Variables |
