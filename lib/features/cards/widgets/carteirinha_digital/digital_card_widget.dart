import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'digital_card_motion_wrapper.dart';
import 'digital_card_background.dart';
import 'digital_card_front.dart';

import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';

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
                  : DigitalCardFront(member: widget.member, card: widget.card),
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
                      : DigitalCardFront(member: widget.member, card: widget.card),
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


String _fmtCpf(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  return cpf;
}


