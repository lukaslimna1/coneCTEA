import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 1. Lidar com preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // 2. Aceitar apenas POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ found: false, masked_email: null, email_sent: false }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 405 }
    )
  }

  try {
    const { cpf } = await req.json()
    
    // 3. Normalizar CPF (remover tudo que não é número)
    const cleanCpf = String(cpf ?? '').replace(/\D/g, '')

    // 4. Validação básica de tamanho
    if (cleanCpf.length !== 11) {
      return new Response(
        JSON.stringify({ found: false, masked_email: null, email_sent: false }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Client Admin (Service Role) - Seguro apenas no backend
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 6. Formatar CPF para busca alternativa (###.###.###-##)
    const formattedCpf = `${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9)}`

    // 7. Buscar apenas o e-mail no banco
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('email')
      .or(`cpf.eq.${cleanCpf},cpf.eq.${formattedCpf}`)
      .maybeSingle()

    if (profileError || !profile || !profile.email) {
      return new Response(
        JSON.stringify({ found: false, masked_email: null, email_sent: false }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const realEmail = profile.email

    // 8. Mascarar e-mail no backend (ex: usuario@gmail.com -> us***@gm***.com)
    const [user, domain] = realEmail.split('@')
    const maskedUser = user.length > 2 ? user.substring(0, 2) + '***' : user + '***'
    
    let maskedDomain = domain
    if (domain.includes('.')) {
      const domainParts = domain.split('.')
      const domainName = domainParts[0]
      const tld = domainParts.slice(1).join('.')
      maskedDomain = (domainName.length > 2 ? domainName.substring(0, 2) + '***' : domainName + '***') + '.' + tld
    } else {
      maskedDomain = domain.length > 2 ? domain.substring(0, 2) + '***' : domain + '***'
    }
    
    const maskedEmail = `${maskedUser}@${maskedDomain}`

    // 9. Disparar instruções de recuperação para o e-mail real
    // TODO: validar deep link final de redefinição de senha em produção
    const { error: resetError } = await supabaseAdmin.auth.resetPasswordForEmail(realEmail, {
      redirectTo: 'io.supabase.conectea://login-callback',
    })

    // 10. Retornar apenas dados seguros
    return new Response(
      JSON.stringify({
        found: true,
        masked_email: maskedEmail,
        email_sent: !resetError
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    // 11. Erro interno: não expor detalhes
    return new Response(
      JSON.stringify({ found: false, masked_email: null, email_sent: false }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  }
})
