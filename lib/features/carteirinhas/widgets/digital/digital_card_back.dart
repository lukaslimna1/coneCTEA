import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'digital_card_background.dart';

import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';

/// Componente que renderiza o verso da carteirinha digital.
/// Contém QR Code de validação, dados de emergência, CID e textos legais.
class DigitalCardBack extends StatelessWidget {
  final Member member;
  final DigitalCard? card;
  final bool showCpf;
  final VoidCallback onToggleCpf;

  const DigitalCardBack({
    super.key,
    required this.member,
    this.card,
    required this.showCpf,
    required this.onToggleCpf,
  });

  @override
  Widget build(BuildContext context) {
    final validationToken = card != null ? card!.cardNumber : '----';
    final qrData = validationToken;

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
                            showCpf
                                ? PhosphorIconsRegular.eyeSlash
                                : PhosphorIconsRegular.eye,
                            size: 18,
                            color: const Color(0xFF00D8D0),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (member.cid.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.45),
                          border: Border.all(
                            color: const Color(
                              0xFF00D8D0,
                            ).withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CID: ',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              member.cid,
                              style: GoogleFonts.inter(
                                color: const Color(
                                  0xFF67E8F9,
                                ), // Ciano suave Sapphire
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  _buildBackItem(
                    'CIDADE / UF',
                    '${member.city} / ${member.state}',
                  ),

                  const Spacer(),

                  // Texto legal
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Carteirinha digital de uso interno da Família TEA Bauru. Não substitui CIPTEA, RG, CPF ou outro documento oficial. A autenticidade pode ser verificada pelo QR Code.',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Seção do QR Code
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
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
                        TextSpan(
                          text: 'Cone',
                          style: TextStyle(color: Color(0xFFA143FF)),
                        ),
                        TextSpan(
                          text: 'CTEA',
                          style: TextStyle(color: Color(0xFF00D8D0)),
                        ),
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

String _fmtCpf(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  return cpf;
}
