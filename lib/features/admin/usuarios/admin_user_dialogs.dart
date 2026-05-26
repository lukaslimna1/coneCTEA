import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/core/constants/colors.dart';

class AdminUserDialogs {
  /// Diálogo para edição de perfil de qualquer usuário pelo Admin
  static void showEditProfileDialog({
    required BuildContext context,
    required AppUser user,
    required DatabaseService databaseService,
    required VoidCallback onUpdateSuccess,
  }) {
    final emailController = TextEditingController(text: user.email);
    final cpfController = TextEditingController(text: user.cpf);
    bool obscureCpf = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
          final double screenHeight = MediaQuery.sizeOf(context).height;
          // Define uma altura máxima útil segura para o diálogo para evitar qualquer overflow
          final double maxHeight = screenHeight - keyboardHeight - 64;

          return AlertDialog(
            backgroundColor: const Color(0xFA0F172A), // Night Blue real do app (Dark Glass denso)
            surfaceTintColor: const Color(0xFA0F172A),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
            title: null, // Deixamos como null para envolver todo o conteúdo no scroll contínuo
            actions: null, // Deixamos como null para evitar concorrência vertical de espaço
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight > 120 ? maxHeight : 120,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0x136366F1), // Índigo translúcido (Privacidade/Segurança)
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF6366F1), // Índigo semântico
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Editar dados sensíveis',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correção de credenciais de ${user.name}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Aviso pequeno de segurança Dark Glass
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x136366F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x266366F1), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.privacy_tip_rounded,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Altere CPF e e-mail com cuidado. Esses dados impactam a identificação e a validação da conta.',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04), // Fundo translúcido sutil
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cpfController,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      obscureText: obscureCpf,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CPF',
                        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04), // Fundo translúcido sutil
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCpf ? PhosphorIcons.eyeClosed(PhosphorIconsStyle.bold) : PhosphorIcons.eye(PhosphorIconsStyle.bold),
                            color: const Color(0xFF6366F1),
                            size: 20,
                          ),
                          tooltip: obscureCpf ? 'Mostrar CPF' : 'Ocultar CPF',
                          onPressed: () {
                            setDialogState(() {
                              obscureCpf = !obscureCpf;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final data = {
                                'email': emailController.text,
                                'cpf': cpfController.text,
                              };

                              try {
                                await databaseService.updateAnyUserProfile(user.id, data);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  onUpdateSuccess();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                                          const SizedBox(width: 12),
                                          const Text('Dados sensíveis atualizados com sucesso!'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.statusGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Não foi possível atualizar o perfil agora. Tente novamente.'),
                                      backgroundColor: AppColors.errorRed,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1), // Cor de privacidade/segurança (Índigo)
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Diálogo para alteração de cargo de um usuário
  static Future<void> changeUserRole({
    required BuildContext context,
    required AppUser user,
    required UserRole newRole,
    required DatabaseService databaseService,
    required VoidCallback onUpdateSuccess,
  }) async {
    if (user.role == newRole) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirmar Alteração',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente mudar o cargo de ${user.name} para ${newRole.name}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await databaseService.updateUserProfileRole(user.id, newRole);
      
      // Como este é um método estático, verificamos se o contexto ainda é válido
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Cargo atualizado com sucesso!'),
            ],
          ),
          backgroundColor: AppColors.statusGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      onUpdateSuccess();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível atualizar o cargo agora. Tente novamente.'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
