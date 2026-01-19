// Main Worker - Routes requests to individual Edge Functions
// This is the entry point for all edge function requests

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname;

  // Health check endpoint
  if (path === "/health" || path === "/" || path === "") {
    return new Response(
      JSON.stringify({
        status: "ok",
        service: "edge-functions",
        version: "1.0.0",
        timestamp: new Date().toISOString(),
        availableFunctions: ["hello", "db-test", "echo"]
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Extract function name from path
  // Supports: /functions/v1/{name} or /{name}
  const functionMatch = path.match(/^(?:\/functions\/v1)?\/([^\/]+)/);

  if (!functionMatch) {
    return new Response(
      JSON.stringify({
        error: "Invalid path",
        path: path,
        hint: "Use /functions/v1/{function-name}",
        availableFunctions: ["hello", "db-test", "echo"]
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const functionName = functionMatch[1];
  const servicePath = `/home/deno/functions/${functionName}`;

  try {
    // Create a user worker for the specific function
    // @ts-ignore - EdgeRuntime is available in Supabase Edge Runtime
    const worker = await EdgeRuntime.userWorkers.create({
      servicePath,
      memoryLimitMb: 150,
      workerTimeoutMs: 60000,
      noModuleCache: false,
      importMapPath: null,
      envVars: [
        ["SUPABASE_URL", Deno.env.get("SUPABASE_URL") || ""],
        ["SUPABASE_ANON_KEY", Deno.env.get("SUPABASE_ANON_KEY") || ""],
        ["SUPABASE_SERVICE_ROLE_KEY", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""],
        ["SUPABASE_DB_URL", Deno.env.get("SUPABASE_DB_URL") || ""],
        ["JWT_SECRET", Deno.env.get("JWT_SECRET") || ""],
      ],
    });

    // Forward the request to the user worker
    return await worker.fetch(req);
  } catch (error) {
    // Function not found or worker creation failed
    const errorMessage = error.message || String(error);

    if (errorMessage.includes("not found") || errorMessage.includes("ENOENT")) {
      return new Response(
        JSON.stringify({
          error: `Function '${functionName}' not found`,
          availableFunctions: ["hello", "db-test", "echo"],
          hint: "Create a new function by adding a directory under functions/ with an index.ts file"
        }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        error: "Function execution failed",
        function: functionName,
        details: errorMessage
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
