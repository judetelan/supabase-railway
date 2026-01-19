// Database Test Edge Function
// Access: /functions/v1/db-test

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      return new Response(
        JSON.stringify({
          error: "Supabase configuration missing",
          supabaseUrl: supabaseUrl ? "set" : "missing",
          supabaseKey: supabaseKey ? "set" : "missing"
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Try a simple query to verify connection
    const { data, error } = await supabase.from('_realtime').select('*').limit(1);

    return new Response(
      JSON.stringify({
        status: "connected",
        message: "Database connection successful",
        function: "db-test",
        supabaseUrl: supabaseUrl,
        queryResult: error ? `Query error: ${error.message}` : "Query successful",
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
