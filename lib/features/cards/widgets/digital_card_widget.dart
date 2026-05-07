import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../models/digital_card.dart';
import '../../../models/member.dart';

class DigitalCardWidget extends StatelessWidget {
  final DigitalCard card;
  final Member member;
  final bool showBack;

  const DigitalCardWidget({
    super.key,
    required this.card,
    required this.member,
    this.showBack = false,
  });

  String get _initials {
    final name = member.name.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      // The aspect ratio for an ID card is typically around 1.58 (standard credit card)
      // We use a fixed height or aspect ratio. Let's use an aspect ratio.
      child: AspectRatio(
        aspectRatio: 0.63, // Portrait mode ID card
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Main content
              Positioned.fill(
                child: showBack ? _buildBack(context) : _buildFront(context),
              ),
              // Blue stripe at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 40,
                child: Container(
                  color: AppColors.primary,
                  alignment: Alignment.center,
                  child: Text(
                    'Válida até ${card.validUntil.day.toString().padLeft(2, '0')}/${card.validUntil.month.toString().padLeft(2, '0')}/${card.validUntil.year}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          SvgPicture.asset(
            'assets/images/logo_horizontal.svg',
            height: 40,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            placeholderBuilder: (context) => Text(
              'ConeCTEA',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'conectando inclusão',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'CARTEIRINHA DE IDENTIFICAÇÃO',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'PESSOA COM TRANSTORNO DO ESPECTRO AUTISTA',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
          
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.purpleLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Member Info
          Text(
            member.name.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          _buildInfoRow('CPF', member.cpf),
          const SizedBox(height: 4),
          _buildInfoRow('RESPONSÁVEL', member.responsibleName.isNotEmpty ? member.responsibleName : 'Não informado'),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'INFORMAÇÕES ADICIONAIS',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Row with info on left, QR on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoColumn('CIDADE / UF', member.city.isNotEmpty ? member.city : 'Não informado'),
                    const SizedBox(height: 16),
                    _buildInfoColumn('CONTATO DE EMERGÊNCIA', member.emergencyContact.isNotEmpty ? member.emergencyContact : 'Não informado'),
                    const SizedBox(height: 16),
                    _buildInfoColumn('VALIDADE DO DOCUMENTO', '${card.validUntil.day.toString().padLeft(2, '0')}/${card.validUntil.month.toString().padLeft(2, '0')}/${card.validUntil.year}'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: QrImageView(
                      data: card.qrValidationUrl,
                      version: QrVersions.auto,
                      size: 90,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'VALIDAR AUTENTICIDADE',
                    style: GoogleFonts.inter(
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // Institutional
          Center(
            child: Column(
              children: [
                Text(
                  'ConeCTEA',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Família TEA Bauru',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#TODOSPELOAUTISMO',
                  style: GoogleFonts.inter(
                    color: AppColors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legal
          Text(
            'Este documento é pessoal e intransferível. O uso indevido está sujeito às penalidades da lei. Em caso de perda, comunique imediatamente a associação.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
