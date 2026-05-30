import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RequestPageHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback? onBackTap;

  const RequestPageHeader({super.key, required this.isEditing, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botão Voltar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              DsBotaoVoltar(
                onPressed:
                    onBackTap ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
              ),
            ],
          ),
        ),

        // Título e Subtítulo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                isEditing ? 'Editar Dependente' : 'Novo Dependente',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre quem receberá a carteirinha.\nPode ser você mesmo ou um dependente.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
