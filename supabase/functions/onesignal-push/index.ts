import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  // 1. CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  // 2. Apenas aceitar POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({
      error: 'Method not allowed'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 405
    });
  }
  try {
    // 3. Obter Secrets (OneSignal)
    const onesignalAppId = Deno.env.get('ONESIGNAL_APP_ID');
    const onesignalRestApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY');
    if (!onesignalAppId || !onesignalRestApiKey) {
      console.error('Falha de configuracao: Secrets ausentes.');
      return new Response(JSON.stringify({
        error: 'Internal configuration error'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }
    // 4. Receber Payload
    const payload = await req.json();
    const record = payload.record;
    // Proteção se não for INSERT ou não tiver record
    if (payload.type !== 'INSERT' || !record || !record.user_id) {
      return new Response(JSON.stringify({
        error: 'Invalid payload or missing user_id'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Mascarar ID no log por precaucao (exibir apenas últimos caracteres se existir)
    const maskedUserId = record.user_id.substring(Math.max(0, record.user_id.length - 4));
    console.log(`Recebida nova notificacao (type: ${record.type}) para user_id terminando em ...${maskedUserId}`);
    // 5. Função/Helper Interna para montar Push Seguro (sem vazar dados reais)
    const getSecurePushContent = (type = '')=>{
      const normalizedType = type.toLowerCase();
      if (normalizedType.includes('active') || normalizedType.includes('approved') || normalizedType === 'card_approved') {
        return {
          title: "Carteirinha atualizada",
          body: "O status da sua carteirinha mudou. Abra o app para conferir."
        };
      }
      if (normalizedType.includes('waiting_docs') || normalizedType === 'doc_pending') {
        return {
          title: "Documentos pendentes",
          body: "Há uma atualização sobre documentos da carteirinha. Abra o app para conferir."
        };
      }
      if (normalizedType.includes('reviewing_data')) {
        return {
          title: "Revisão de dados",
          body: "Há uma atualização sobre revisão de dados. Abra o app para conferir."
        };
      }
      if (normalizedType.includes('rejected')) {
        return {
          title: "Aviso importante",
          body: "O status da sua solicitação foi atualizado. Abra o app para conferir."
        };
      }
      if (normalizedType.includes('suspended')) {
        return {
          title: "Carteirinha atualizada",
          body: "O status da sua carteirinha mudou. Abra o app para conferir."
        };
      }
      if (normalizedType.includes('expired')) {
        return {
          title: "Carteirinha vencida",
          body: "Uma carteirinha expirou. Abra o app para conferir."
        };
      }
      if (normalizedType.includes('renewing')) {
        return {
          title: "Renovação em andamento",
          body: "Há uma atualização sobre renovação. Abra o app para conferir."
        };
      }
      if (normalizedType === 'event') {
        return {
          title: "Novo aviso de evento",
          body: "Você recebeu uma notificação de evento. Abra o app para conferir."
        };
      }
      if (normalizedType === 'project') {
        return {
          title: "Novo aviso de projeto",
          body: "Você recebeu uma notificação de projeto. Abra o app para conferir."
        };
      }
      if (normalizedType === 'clube' || normalizedType === 'partner' || normalizedType === 'new_partner') {
        return {
          title: "Clube ConeCTEA",
          body: "Há uma nova atualização do Clube. Abra o app para conferir."
        };
      }
      if (normalizedType === 'general_notice') {
        return {
          title: "Novo comunicado",
          body: "Você recebeu um comunicado da Família TEA Bauru. Abra o app para conferir."
        };
      }
      return {
        title: "Nova notificação",
        body: "Você recebeu uma nova notificação. Abra o app para conferir."
      };
    };
    const secureContent = getSecurePushContent(record.type);
    // 6. Chamada OneSignal
    const oneSignalPayload = {
      app_id: onesignalAppId,
      include_aliases: {
        external_id: [
          record.user_id
        ]
      },
      target_channel: "push",
      headings: {
        pt: secureContent.title,
        en: secureContent.title
      },
      contents: {
        pt: secureContent.body,
        en: secureContent.body
      },
      data: {
        source: "conectea",
        type: record.type ?? "general_notice"
      }
    };
    const response = await fetch('https://api.onesignal.com/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${onesignalRestApiKey}`
      },
      body: JSON.stringify(oneSignalPayload)
    });
    if (!response.ok) {
      console.error(`OneSignal API respondeu com status HTTP: ${response.status}`);
      return new Response(JSON.stringify({
        error: 'Failed to dispatch push notification'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }
    console.log('Notificacao remota disparada com sucesso.');
    return new Response(JSON.stringify({
      success: true
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    console.error('Erro interno na Edge Function');
    return new Response(JSON.stringify({
      error: 'Internal server error'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
