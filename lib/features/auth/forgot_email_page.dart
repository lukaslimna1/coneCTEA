import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class ForgotEmailPage extends StatefulWidget {
  const ForgotEmailPage({super.key});

  @override
  State<ForgotEmailPage> createState() => _ForgotEmailPageState();
}

class _ForgotEmailPageState extends State<ForgotEmailPage> {
  final _cpfController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  String? _foundEmail;
  String? _error;
  bool _resetSent = false;

  Future<void> _lookupEmail() async {
    final cpf = _cpfFormatter.getUnmaskedText();
    if (cpf.length != 11) {
      setState(() => _error = 'Informe um CPF válido');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _foundEmail = null;
    });

    try {
      final email = await DatabaseService().getEmailByCpf(cpf);
      if (email != null) {
        setState(() => _foundEmail = email);
      } else {
        setState(() => _error = 'Nenhuma conta encontrada com este CPF');
      }
    } catch (e) {
      setState(() => _error = 'Erro ao buscar e-mail. Tente novamente.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_foundEmail == null) return;
    
    if (_resetSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail já enviado recentemente. Por favor, verifique sua caixa de entrada ou aguarde alguns minutos.'),
          backgroundColor: AppColors.alertOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().sendPasswordResetEmail(_foundEmail!);
      setState(() => _resetSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail de redefinição enviado! Verifique sua caixa de entrada.'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Erro ao enviar e-mail: $e';
      Color bgColor = AppColors.errorRed;

      if (e.toString().contains('over_email_send_rate_limit') || e.toString().contains('429')) {
        errorMessage = 'Muitas solicitações. Por favor, verifique seu e-mail ou tente novamente em alguns minutos.';
        bgColor = AppColors.alertOrange;
        setState(() => _resetSent = true); // Mark as sent to prevent immediate retries
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: bgColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPremium,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alternate_email_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Esqueci meu e-mail',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Informe o CPF cadastrado para localizarmos seu acesso.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            if (_foundEmail == null) ...[
              Text(
                'CPF',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cpfController,
                inputFormatters: [_cpfFormatter],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '000.000.000-00',
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _lookupEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Buscar E-mail', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.statusGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.statusGreen.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.statusGreen, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'E-mail localizado!',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkBlue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seu e-mail de acesso é:',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _foundEmail!,
                      style: GoogleFonts.inter(
                        fontSize: 20, 
                        fontWeight: FontWeight.w900, 
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Deseja também redefinir sua senha?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendPasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_resetSent ? 'Reenviar E-mail' : 'Enviar Redefinição de Senha', 
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Center(
                  child: Text(
                    'Voltar para o Login',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
