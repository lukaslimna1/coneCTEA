import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'digital_card_motion_wrapper.dart';
import 'digital_card_background.dart';

import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/core/widgets/premium_avatar.dart';
import 'package:conectea/core/constants/colors.dart';

class DigitalCardWidget extends StatefulWidget {
  final DigitalCard? card;
  final Member member;
  final bool showBack;
  final bool enableParallax;
  final bool enableEntryAnimation;
  final bool isStatic;
  final bool? showCpf;
  final VoidCallback? onToggleCpf;

  const DigitalCardWidget({
    super.key,
    this.card,
    required this.member,
    this.showBack = false,
    this.enableParallax = true,
    this.enableEntryAnimation = true,
    this.isStatic = false,
    this.showCpf,
    this.onToggleCpf,
  });

  @override
  State<DigitalCardWidget> createState() => _DigitalCardWidgetState();
}

class _DigitalCardWidgetState extends State<DigitalCardWidget> {
  bool _internalShowCpf = false;

  bool get _effectiveShowCpf => widget.showCpf ?? _internalShowCpf;
  
  void _handleToggleCpf() {
    if (widget.onToggleCpf != null) {
      widget.onToggleCpf?.call();
    } else {
      setState(() => _internalShowCpf = !_internalShowCpf);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isStatic) {
      return AspectRatio(
        aspectRatio: 1.58,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 450,
              height: 450 / 1.58,
              child: widget.showBack
                  ? _BackCard(
                      member: widget.member, 
                      card: widget.card,
                      showCpf: _effectiveShowCpf,
                      onToggleCpf: _handleToggleCpf,
                    )
                  : _FrontCard(member: widget.member, card: widget.card),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.58, // Proporção padrão de cartão de crédito
      child: DigitalCardMotionWrapper(
        enabled: widget.enableParallax,
        enableEntryAnimation: widget.enableEntryAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 450, // Largura Premium
                  height: 450 / 1.58,
                  child: widget.showBack
                      ? _BackCard(
                          member: widget.member, 
                          card: widget.card,
                          showCpf: _effectiveShowCpf,
                          onToggleCpf: _handleToggleCpf,
                        )
                      : _FrontCard(member: widget.member, card: widget.card),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════
//  FRENTE (FRONT)
// ═══════════════════════════════════════════════════
class _FrontCard extends StatelessWidget {
  final Member member;
  final DigitalCard? card;
  const _FrontCard({required this.member, this.card});

  @override
  Widget build(BuildContext context) {
    final birthStr = _parseDate(member.dateOfBirth);
    final validStr = card != null ? _parseDate(card!.validUntil.toIso8601String()) : '--/--/----';
    final validationToken = card != null ? card!.cardNumber : '----';
    
    final status = card?.status ?? 'pending';
    final isActive = status == 'active';
    final isExpired = card != null && card!.validUntil.isBefore(DateTime.now());

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
                
                // Pills side by side
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Validity Pill — Estilo Glassmorphism Refinado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2445).withValues(alpha: 0.9), // Mais escuro para melhor contraste
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
                            color: isExpired ? AppColors.errorRed : const Color(0xFFA78BFA), // Roxo mais brilhante
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            validStr,
                            style: GoogleFonts.inter(
                              color: isExpired ? AppColors.errorRed : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Pill — Dinâmico e Vibrante
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.statusGreen : AppColors.alertOrange).withValues(alpha: 0.95), // Altamente visível
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? AppColors.statusGreen : AppColors.alertOrange).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.clockCounterClockwise, 
                            color: Colors.white, // Alto contraste no fundo
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'ATIVA' : (
                              status == 'waiting_approval' || status == 'pending' ? 'PENDENTE' :
                              status == 'reviewing_data' ? 'PENDENTE' :
                              status == 'waiting_docs' ? 'DOCS PEND.' :
                              status == 'suspended' ? 'SUSPENSA' :
                              status == 'rejected' ? 'REPROVADA' : 'INATIVA'
                            ),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
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
}

// ═══════════════════════════════════════════════════
//  VERSO (BACK)
// ═══════════════════════════════════════════════════
class _BackCard extends StatelessWidget {
  final Member member;
  final DigitalCard? card;
  final bool showCpf;
  final VoidCallback onToggleCpf;
  
  const _BackCard({
    required this.member, 
    this.card,
    required this.showCpf,
    required this.onToggleCpf,
  });

  @override
  Widget build(BuildContext context) {
    final validationToken = card != null ? card!.cardNumber : '----';
    final qrData = validationToken;
    // Removed unused validStr variable

    return DigitalCardBackground(
      isFront: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Conteúdo Esquerdo (Dados)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INFORMAÇÕES ADICIONAIS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF4299E1), // Azul Claro
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C5282), // Azul Médio
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: onToggleCpf,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildBackItem(
                        'CPF', 
                        showCpf ? _fmtCpf(member.cpf) : '***.***.***-**',
                        trailing: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            showCpf ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                            size: 18,
                            color: const Color(0xFF00D8D0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (member.cid.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          border: Border.all(color: const Color(0xFFA143FF).withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CID: ${member.cid}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA143FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                  _buildBackItem('CIDADE / UF', '${member.city} / ${member.state}'),
                  _buildBackItem('CONTATO DE EMERGÊNCIA', member.emergencyContact),
                  
                  const Spacer(),
                  
                  // Legal Text
                  Text(
                    'Documento de identificação digital para uso exclusivo nos programas da Família TEA Bauru.\nNão substitui a CIPTEA oficial (Lei 13.977/20) ou outros documentos de identidade legais.\nA autenticidade pode ser verificada via QR Code.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // QR Code Section
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 110.0,
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1A1F71),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A1F71),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VALIDAR AUTENTICIDADE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      children: const [
                        TextSpan(text: 'Cone', style: TextStyle(color: Color(0xFFA143FF))),
                        TextSpan(text: 'CTEA', style: TextStyle(color: Color(0xFF00D8D0))),
                      ],
                    ),
                  ),
                  Text(
                    'Família TEA Bauru',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#TODOSPELOAUTISMO',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00D8D0),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackItem(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════

String _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return '---';
  try {
    final d = DateTime.parse(raw);
    return DateFormat('dd/MM/yyyy').format(d);
  } catch (_) {
    return raw;
  }
}

String _fmtCpf(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  return cpf;
}


