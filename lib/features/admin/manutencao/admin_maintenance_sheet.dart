import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';

class AdminMaintenanceSheet extends StatelessWidget {
  const AdminMaintenanceSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AdminMaintenanceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = ConecteaVisualTokens.manutencaoTecnica;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFB0B132B), // Fundo premium Night Blue profundo
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: token.accent.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alça de arraste visual premium
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Cabeçalho da Central
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: token.softBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: token.border, width: 1),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.wrench,
                        color: token.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Manutenção',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: token.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: token.accent.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'ADMIN DEV',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: token.accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Área técnica restrita para recursos internos do app.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Aviso discreto de área técnica
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.warning,
                        color: Colors.amber.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recursos desta área devem ser usados apenas para diagnóstico e controle técnico.',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Módulo 1: Controle de Recursos
                _buildMaintenanceCard(
                  icon: PhosphorIconsRegular.sliders,
                  title: 'Controle de Recursos',
                  description:
                      'Ativar ou desativar temporariamente módulos e ações com problema.',
                  statusLabel: 'Planejado',
                  isFuture: false,
                ),

                // Módulo 2: Diagnóstico do Sistema
                _buildMaintenanceCard(
                  icon: PhosphorIconsRegular.pulse,
                  title: 'Diagnóstico do Sistema',
                  description:
                      'Verificar integrações, serviços e rotinas técnicas do app.',
                  statusLabel: 'Planejado',
                  isFuture: false,
                ),

                // Módulo 3: Rotinas Automáticas
                _buildMaintenanceCard(
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  title: 'Rotinas Automáticas',
                  description:
                      'Acompanhar limpezas e validações executadas pelo sistema.',
                  statusLabel: 'Planejado',
                  isFuture: false,
                ),

                // Módulo 4: Auditoria Técnica
                _buildMaintenanceCard(
                  icon: PhosphorIconsRegular.fileText,
                  title: 'Auditoria Técnica',
                  description:
                      'Consultar registros de ações administrativas sensíveis.',
                  statusLabel: 'Futuro',
                  isFuture: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard({
    required IconData icon,
    required String title,
    required String description,
    required String statusLabel,
    required bool isFuture,
  }) {
    final token = ConecteaVisualTokens.manutencaoTecnica;
    final statusColor = isFuture ? const Color(0xFF94A3B8) : token.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xD90F172A), // Dark glass premium
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFuture
              ? Colors.white.withValues(alpha: 0.05)
              : token.accent.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFuture
                ? Colors.black.withValues(alpha: 0.2)
                : token.accent.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFuture
                  ? Colors.white.withValues(alpha: 0.03)
                  : token.softBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFuture
                    ? Colors.white.withValues(alpha: 0.06)
                    : token.border,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isFuture ? const Color(0xFF94A3B8) : token.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
