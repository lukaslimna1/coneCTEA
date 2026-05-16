import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'digital_card_background.dart';

import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/core/widgets/premium_avatar.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

/// Componente que renderiza a frente da carteirinha digital.
/// Contém dados básicos do membro, foto, validade e status.
class DigitalCardFront extends StatelessWidget {
  final Member member;
  final DigitalCard? card;

  const DigitalCardFront({
    super.key,
    required this.member,
    this.card,
  });

  @override
  Widget build(BuildContext context) {
    final birthStr = _parseDate(member.dateOfBirth);
    final validStr = card != null ? _parseDate(card!.validUntil.toIso8601String()) : '--/--/----';
    final validationToken = card != null ? card!.cardNumber : '----';

    final status = card?.status ?? 'pending';
    final isExpired = card != null && card!.validUntil.isBefore(DateTime.now());
    
    // Resolve tokens de status (se estiver expirado, força o token de expiração)
    final effectiveStatus = isExpired ? 'expired' : status;
    final tokens = StatusVisualTokens.fromStatus(effectiveStatus);

    final bool hasValidBloodType = member.bloodType.isNotEmpty && 
        !member.bloodType.toLowerCase().contains('não sei') && 
        !member.bloodType.toLowerCase().contains('prefiro');

    return DigitalCardBackground(
      isFront: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo do Cabeçalho e Pílulas Superiores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 215, // Logo horizontal ~45% a 60% da largura da carteirinha
                    maxHeight: 36, // Logo horizontal pequena/média
                  ),
                  child: Image.asset(
                    'assets/images/conectea_logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'ConeCTEA',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                
                // Pílulas lado a lado
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pílula de Validade — Estilo Glassmorphism Refinado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2445).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsBold.calendar, 
                            color: isExpired ? StatusVisualTokens.fromStatus('expired').primary : const Color(0xFFA78BFA),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            validStr,
                            style: GoogleFonts.inter(
                              color: isExpired ? StatusVisualTokens.fromStatus('expired').primary : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pílula de Status — Dinâmico e Vibrante (Referência: Badge NOVO)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: tokens.pillBorder,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Overlay da cor do status sutil
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: tokens.pillBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tokens.icon,
                                color: tokens.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tokens.label.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: tokens.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Título
            Text(
              'CARTEIRINHA DE IDENTIFICAÇÃO',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PESSOA COM TRANSTORNO DO ESPECTRO AUTISTA',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            
            const Spacer(),

            // Linha de Dados do Membro
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PremiumAvatar(
                  initials: member.initials,
                  size: 90,
                  borderWidth: 3,
                  paletteSeed: member.userId,
                ),
                const SizedBox(width: 24),
                // Informação Principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        birthStr,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (member.responsibleName.isNotEmpty)
                        Text(
                          'Resp: ${member.responsibleName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (hasValidBloodType)
                        Text(
                          'Tipo Sanguíneo: ${member.bloodType}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF6B6B), // Vermelho claro sobre escuro
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Linha do Token no Rodapé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Pílula do Token
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.hash, color: Color(0xFF4299E1), size: 8),
                      const SizedBox(width: 4),
                      Text(
                        'TOKEN: ',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        validationToken,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return '---';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return raw;
    }
  }
}
