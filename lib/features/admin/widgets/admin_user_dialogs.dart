import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final cpfController = TextEditingController(text: user.cpf);
    final cityController = TextEditingController(text: user.city ?? '');
    final stateController = TextEditingController(text: user.state ?? '');
    String? selectedGenero = user.gender;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Editar Cadastro: ${user.name}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                TextField(
                  controller: cpfController,
                  decoration: const InputDecoration(labelText: 'CPF'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: [
                    'Feminino',
                    'Masculino',
                    'Não binário',
                    'Outro',
                    'Prefiro não informar',
                  ].contains(selectedGenero) ? selectedGenero : null,
                  decoration: const InputDecoration(labelText: 'Gênero'),
                  hint: const Text('Selecione o gênero'),
                  items: [
                    'Feminino',
                    'Masculino',
                    'Não binário',
                    'Outro',
                    'Prefiro não informar',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => selectedGenero = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'cpf': cpfController.text,
                  'city': cityController.text,
                  'state': stateController.text,
                  'gender': selectedGenero,
                };

                try {
                  await databaseService.updateAnyUserProfile(user.id, data);
                  if (context.mounted) {
                    Navigator.pop(context);
                    onUpdateSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Perfil atualizado com sucesso!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível atualizar o perfil agora. Tente novamente.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
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
