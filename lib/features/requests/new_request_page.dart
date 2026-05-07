import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/google_drive_service.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/member.dart';
import '../../models/card_request.dart';

class NewRequestPage extends StatefulWidget {
  final Member member;

  const NewRequestPage({super.key, required this.member});

  @override
  State<NewRequestPage> createState() => _NewRequestPageState();
}

class _NewRequestPageState extends State<NewRequestPage> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final GoogleDriveService _driveService = GoogleDriveService();

  bool _isLoading = false;
  bool _termsAccepted = false;
  String _requestType = 'Primeira via';

  final List<String> _requestTypes = [
    'Primeira via',
    'Atualização de Dados',
  ];

  PlatformFile? _idPhotoFile;
  PlatformFile? _medicalReportFile;
  String? _idPhotoUrl;
  String? _medicalReportUrl;
  bool _isUploadingDocs = false;

  Future<void> _pickDocument(bool isIdPhoto) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        if (isIdPhoto) {
          _idPhotoFile = result.files.first;
        } else {
          _medicalReportFile = result.files.first;
        }
      });
    }
  }

  Future<String?> _uploadFile(
    PlatformFile file,
    String protocol,
    String typeLabel,
  ) async {
    try {
      final extension = file.extension ?? 'bin';
      final fileName =
          '${protocol}_${widget.member.name.replaceAll(' ', '_')}_$typeLabel.$extension';

      return await _driveService.uploadFile(file: file, fileName: fileName);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os termos para continuar'),
        ),
      );
      return;
    }

    if (_idPhotoFile == null || _medicalReportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, anexe todos os documentos obrigatórios'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final random = const Uuid().v4().substring(0, 4).toUpperCase();
      final protocol = 'REQ-$dateStr-$random';

      // 1. Upload Documents
      setState(() => _isUploadingDocs = true);

      _idPhotoUrl = await _uploadFile(_idPhotoFile!, protocol, 'DOC_FOTO');
      _medicalReportUrl = await _uploadFile(
        _medicalReportFile!,
        protocol,
        'LAUDO_MEDICO',
      );

      if (_idPhotoUrl == null || _medicalReportUrl == null) {
        throw Exception(
          'Erro ao fazer upload dos documentos. Verifique sua conexão.',
        );
      }

      final request = CardRequest(
        id: const Uuid().v4(),
        userId: userId,
        memberId: widget.member.id,
        type: _requestType,
        status: 'under_review',
        protocol: protocol,
        adminNotes: '',
        driveFolderUrl:
            '', // This will hold the storage path if needed, or just leave as legacy
        documentUrl: _idPhotoUrl!,
        medicalReportUrl: _medicalReportUrl!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.createCardRequest(request);

      if (mounted) {
        _showSuccessDialog(protocol);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String protocol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.statusGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.statusGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Solicitação Enviada!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sua solicitação foi registrada com sucesso sob o protocolo:',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Text(
                protocol,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home'); // Volta para a home e reseta a pilha
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Voltar para o Início',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Confirmar Solicitação',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMemberSummary(),
            const SizedBox(height: 32),

            Text(
              'Tipo de Solicitação',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTypeSelector(),

            const SizedBox(height: 32),
            _buildInfoBox(),

            const SizedBox(height: 32),
            _buildDocumentUploadSection(),

            const SizedBox(height: 32),
            _buildTermsCheckbox(),

            const SizedBox(height: 48),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beneficiário',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  widget.member.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'CPF: ${widget.member.cpf}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: _requestTypes.map((type) {
          final isSelected = _requestType == type;
          return InkWell(
            onTap: () => setState(() => _requestType = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: type != _requestTypes.last
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.03),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximos passos',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anexe os documentos abaixo. Seus arquivos serão salvos com segurança e nomeados com o protocolo e nome do beneficiário para facilitar a análise.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentação Obrigatória',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildUploadCard(
          title: 'Documento com Foto',
          subtitle: 'RG ou CNH (Frente e Verso)',
          file: _idPhotoFile,
          onTap: () => _pickDocument(true),
        ),
        const SizedBox(height: 12),
        _buildUploadCard(
          title: 'Laudo Médico',
          subtitle: 'Laudo com CID que comprove o TEA',
          file: _medicalReportFile,
          onTap: () => _pickDocument(false),
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    PlatformFile? file,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? AppColors.statusGreen.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.05),
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.statusGreen.withValues(alpha: 0.1)
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_rounded
                    : Icons.file_upload_outlined,
                color: hasFile
                    ? AppColors.statusGreen
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    hasFile ? file.name : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: hasFile
                          ? AppColors.statusGreen
                          : AppColors.textSecondary,
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasFile)
              const Icon(
                Icons.edit_outlined,
                color: AppColors.textSecondary,
                size: 20,
              )
            else
              const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Checkbox(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              'Declaro que as informações acima são verdadeiras e estou ciente da análise documental.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isUploadingDocs
                        ? 'Enviando documentos...'
                        : 'Processando...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                'Enviar Solicitação',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
