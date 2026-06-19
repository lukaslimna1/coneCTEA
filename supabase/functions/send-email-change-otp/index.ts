import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sendExistingEmailChangeOtp } from "./delivery.ts";
import { createCorrelationId } from "./signing.ts";

declare const Deno: any;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export async function handler(req: Request): Promise<Response> {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 2. Aceita apenas POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "method_not_allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 3. Gerar Correlation ID operacional para rastreio
  const correlationId = createCorrelationId();

  try {
    // 4. Validar JWT no cabeçalho Authorization
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error(`[Correlation ID: ${correlationId}] Configuração de ambiente ausente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia cliente anon para validar o token
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // O auth_user_id derivado do JWT é nossa autoridade
    const authUserId = user.id;

    // 5. Ler parâmetros operacionais mínimos do body e validar chaves proibidas
    const body = await req.json();

    if ("user_id" in body || "auth_user_id" in body) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { cycle_id, challenge_id } = body;

    if (!cycle_id || !challenge_id) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Instanciar Supabase Admin client com service role
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      console.error(`[Correlation ID: ${correlationId}] SUPABASE_SERVICE_ROLE_KEY ausente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // 7. Chamar fluxo de entrega encapsulado no delivery.ts
    const result = await sendExistingEmailChangeOtp({
      supabaseAdmin,
      authUserId,
      cycleId: cycle_id,
      challengeId: challenge_id,
      correlationId
    });

    return new Response(
      JSON.stringify(result.body),
      {
        status: result.httpStatus,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );

  } catch (err) {
    console.error(`[Correlation ID: ${correlationId}] Erro interno na Edge Function.`);
    return new Response(
      JSON.stringify({ error: "internal_server_error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

if ((import.meta as any).main) {
  serve(handler);
}
