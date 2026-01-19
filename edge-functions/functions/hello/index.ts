// Hello World Edge Function
// Access: /functions/v1/hello

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
    const body = await req.json().catch(() => ({}));
    const name = body.name || "World";

    return new Response(
      JSON.stringify({
        message: `Hello ${name}!`,
        timestamp: new Date().toISOString(),
        function: "hello",
        environment: {
          supabaseUrl: Deno.env.get("SUPABASE_URL") ? "configured" : "not set",
          jwtSecret: Deno.env.get("JWT_SECRET") ? "configured" : "not set",
        }
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
