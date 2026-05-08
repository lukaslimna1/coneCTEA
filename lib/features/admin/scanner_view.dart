import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import 'package:intl/intl.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isScanning = true;
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() {
          _isProcessing = true;
          _isScanning = false;
        });

        // Extrair o número da carteirinha de forma robusta
        String extracted = code.trim();
        
        // Se for uma URL, pegamos apenas o que vem depois do último '/'
        if (extracted.contains('/')) {
          // Remove barra final se houver antes de dar o split
          if (extracted.endsWith('/')) {
            extracted = extracted.substring(0, extracted.length - 1);
          }
          extracted = extracted.split('/').last;
        }
        
        // Remove qualquer parâmetro de query (?...) ou fragmento (#...)
        if (extracted.contains('?')) {
          extracted = extracted.split('?').first;
        }
        if (extracted.contains('#')) {
          extracted = extracted.split('#').first;
        }

        final String cardNumber = extracted.trim();
        debugPrint('ScannerView: Original Code: "$code"');
        debugPrint('ScannerView: Extracted Token: "$cardNumber"'); 
        
        _validateCard(cardNumber);
        break;
      }
    }
  }

  Future<void> _validateCard(String cardNumber) async {
    try {
      final card = await _databaseService.getCardByNumber(cardNumber);
      
      if (!mounted) return;

      if (card == null) {
        _showResultSheet(
          isValid: false,
          title: 'Não Encontrada',
          message: 'A carteirinha informada não existe em nossa base.',
        );
      } else {
        final isExpired = card.validUntil.isBefore(DateTime.now());
        final isActive = card.status == 'active';
        
        // Se o getCardByNumber retornou o member via join, ele estaria no JSON
        // Mas como o modelo não tem o campo member, vamos buscar manualmente se necessário
        // ou assumir que frontData tem o nome.
        final name = card.frontData['name'] ?? 'Membro';

        _showResultSheet(
          isValid: isActive && !isExpired,
          card: card,
          title: isActive && !isExpired ? 'Carteirinha Válida' : 'Carteirinha Inválida',
          message: isExpired 
              ? 'Esta carteirinha está vencida desde ${DateFormat('dd/MM/yyyy').format(card.validUntil)}.'
              : !isActive 
                  ? 'Esta carteirinha foi desativada pelo administrador.'
                  : 'Documento original e válido.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao validar: $e')),
        );
      }
      setState(() {
        _isProcessing = false;
        _isScanning = true;
      });
    }
  }

  void _showResultSheet({
    required bool isValid,
    DigitalCard? card,
    required String title,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isValid ? Colors.green : Colors.red).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isValid ? Icons.check_circle_outline : Icons.error_outline,
                color: isValid ? Colors.green : Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            if (card != null) ...[
              const SizedBox(height: 24),
              _buildInfoRow('Nome:', card.frontData['name'] ?? 'N/A'),
              _buildInfoRow('Número:', card.cardNumber),
              _buildInfoRow('Validade:', DateFormat('dd/MM/yyyy').format(card.validUntil)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isProcessing = false;
                    _isScanning = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Escanear Outra'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            controller: MobileScannerController(
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
          ),
          // Overlay
          _buildOverlay(),
          // Header
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                ),
                Text(
                  'Validar Carteirinha',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 48), // Spacer
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                _buildCorner(0, 0), // Top left
                _buildCorner(1, 0), // Top right
                _buildCorner(0, 1), // Bottom left
                _buildCorner(1, 1), // Bottom right
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Aponte para o QR Code',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(int x, int y) {
    return Positioned(
      top: y == 0 ? -2 : null,
      bottom: y == 1 ? -2 : null,
      left: x == 0 ? -2 : null,
      right: x == 1 ? -2 : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: y == 0 ? BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: y == 1 ? BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: x == 0 ? BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: x == 1 ? BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: x == 0 && y == 0 ? const Radius.circular(24) : Radius.zero,
            topRight: x == 1 && y == 0 ? const Radius.circular(24) : Radius.zero,
            bottomLeft: x == 0 && y == 1 ? const Radius.circular(24) : Radius.zero,
            bottomRight: x == 1 && y == 1 ? const Radius.circular(24) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
