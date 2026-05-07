import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import '../../models/id_request.dart';
import '../../core/app_theme.dart';

class MyIDScreen extends StatefulWidget {
  final List<IDRequest> requests;
  final int initialIndex;

  const MyIDScreen({
    super.key, 
    required this.requests, 
    this.initialIndex = 0,
  });

  @override
  State<MyIDScreen> createState() => _MyIDScreenState();
}

class _MyIDScreenState extends State<MyIDScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  int _currentIndex = 0;
  bool _isManualRotation = false; // Suporte para Web/Simulação

  @override
  void initState() {
    super.initState();
    // Permite ambas as orientações, mas o app é majoritariamente vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Esconde a barra de status para imersão total
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Força volta para vertical ao sair para não quebrar o resto do app
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _toggleOrientation() {
    if (kIsWeb) {
      setState(() {
        _isManualRotation = !_isManualRotation;
      });
      return;
    }

    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    if (names.isNotEmpty && names[0].isNotEmpty) {
      initials += names[0][0];
    }
    if (names.length > 1 && names[names.length - 1].isNotEmpty) {
      initials += names[names.length - 1][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    // Em Web, usamos o estado manual. No Mobile, usamos a orientação real do device.
    final bool isLandscape = kIsWeb ? _isManualRotation : (orientation == Orientation.landscape);
    
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: MediaQuery(
        // Força escala 1.0 para evitar quebras por acessibilidade do sistema
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Stack(
          children: [
            // Background decorativo (opcional, mas adiciona premium feel)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: GridPainter(),
                ),
              ),
            ),

            PageView.builder(
              controller: _pageController,
              itemCount: widget.requests.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  if (!_isFront) {
                    _flipController.reverse();
                    _isFront = true;
                  }
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 0 : 16,
                      vertical: isLandscape ? 0 : 20,
                    ),
                    child: GestureDetector(
                      onTap: _toggleFlip,
                      child: RotatedBox(
                        quarterTurns: (kIsWeb && _isManualRotation) ? 1 : 0,
                        child: _buildAnimatedCard(widget.requests[index], isLandscape),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Botões de Topo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderButton(
                        icon: Icons.close_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          _buildHeaderButton(
                            icon: isLandscape ? Icons.screen_lock_portrait_rounded : Icons.screen_rotation_rounded,
                            onPressed: _toggleOrientation,
                            color: isLandscape ? AppColors.teal : Colors.black.withValues(alpha: 0.3),
                            iconColor: isLandscape ? AppColors.navy : Colors.white,
                          ),
                          if (widget.requests.length > 1) ...[
                            const SizedBox(width: 12),
                            _buildHeaderButton(
                              icon: Icons.swap_horiz_rounded,
                              onPressed: () => _showPicker(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Lembrete de Rotação (Apenas em Portrait)
            if (!isLandscape)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.screen_rotation_rounded, color: AppColors.teal, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'GIRE PARA VISIBILIDADE TOTAL',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Indicador de Posição
            if (widget.requests.length > 1)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.requests.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? AppColors.teal : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon, 
    required VoidCallback onPressed, 
    Color? color,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildAnimatedCard(IDRequest request, bool isLandscape) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: angle < math.pi / 2
              ? _buildCardSide(request, true, isLandscape)
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildCardSide(request, false, isLandscape),
                ),
        );
      },
    );
  }

  Widget _buildCardSide(IDRequest request, bool isFront, bool isLandscape) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Largura máxima: 96% em landscape, 92% em portrait
        final availableWidth = constraints.maxWidth * (isLandscape ? 0.96 : 0.92);
        // Altura baseada na proporção de cartão (1.724:1 ou similar)
        // Usamos 800x464 como sistema de coordenadas interno
        
        return Container(
          width: availableWidth,
          height: isLandscape ? null : availableWidth / (800 / 464),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 800,
                height: 464,
                child: isFront ? _buildFrontLayout(request) : _buildBackLayout(request),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontLayout(IDRequest request) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navy,
      ),
      child: Stack(
        children: [
          // Elementos Decorativos de Fundo
          Positioned(
            right: -50,
            top: -50,
            child: _buildDecorativeCircle(250, AppColors.purple.withValues(alpha: 0.05)),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: _buildDecorativeCircle(200, AppColors.teal.withValues(alpha: 0.03)),
          ),

          // Header Brand (Canto Superior Direito - Menor)
          const Positioned(
            top: 24,
            right: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_rounded, color: AppColors.teal, size: 22),
                SizedBox(width: 8),
                Text(
                  'ConeCTEA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                // Coluna Esquerda: Selo e Status
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Selo Visual Institucional (Substituindo a Foto)
                    Container(
                      width: 200,
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blue.withValues(alpha: 0.15),
                            AppColors.purple.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.4), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getInitials(request.applicantName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 84,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Icon(Icons.verified_user_rounded, color: AppColors.teal, size: 40),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Badge de Membro
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.teal, AppColors.success],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'MEMBRO ATIVO',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Símbolo do Infinito
                    Image.network(
                      'https://raw.githubusercontent.com/lukaslimna1/assets/main/tea_badge.png',
                      height: 54,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.all_inclusive_rounded, color: AppColors.teal, size: 54),
                    ),
                  ],
                ),
                
                const SizedBox(width: 40),
                
                // Coluna Direita: Dados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 54), // Espaço para o ConeCTEA no topo
                      
                      // Nome (Grande e Forte)
                      Text(
                        request.applicantName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 38,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Campos (Ocupando a linha toda)
                      _buildDataField('Nº REGISTRO', request.cardNumber ?? 'EMISSÃO...'),
                      const SizedBox(height: 4),
                      _buildDataField('CPF / RG', request.rgCpf),
                      
                      const Spacer(),
                      
                      // Rodapé do Card (Alinhado com o Infinito à Esquerda)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Text(
                            'DOCUMENTO DIGITAL OFICIAL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4), // Pequeno ajuste para alinhar com o símbolo do infinito
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackLayout(IDRequest request) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Logo Watermark
          const Positioned(
            right: -60,
            bottom: -60,
            child: Opacity(
              opacity: 0.04,
              child: Icon(Icons.psychology_rounded, size: 400, color: AppColors.navy),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                // Info Adicional
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'INFORMAÇÕES ADICIONAIS',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: 2,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 4,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildBackDataField('CIDADE / UF', request.city),
                      _buildBackDataField('INSTITUIÇÃO', request.institution),
                      _buildBackDataField('CONTATO EMERGÊNCIA', request.phone),
                      _buildBackDataField('VALIDADE DO DOCUMENTO', _formatDate(request.expiryDate)),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Este documento é pessoal e intransferível. A autenticidade pode ser verificada via QR Code. Válido em todo território nacional.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 40),
                
                // QR e Logos
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: AppColors.navy.withValues(alpha: 0.08), width: 2),
                      ),
                      child: QrImageView(
                        data: request.cardNumber ?? request.id,
                        version: QrVersions.auto,
                        size: 160.0,
                        padding: EdgeInsets.zero,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.navy,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VALIDAR AUTENTICIDADE',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Marcas Relacionadas
                    _buildRelatedBrands(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackDataField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedBrands() {
    return const Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_rounded, color: AppColors.navy, size: 24),
            SizedBox(width: 8),
            Text(
              'ConeCTEA',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Família TEA Bauru',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          '#TODOSPELOAUTISMO',
          style: TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Selecionar Carteirinha',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: widget.requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = widget.requests[index];
                  final isSelected = _currentIndex == index;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pageController.animateToPage(
                        index, 
                        duration: const Duration(milliseconds: 500), 
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.05),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.blue, AppColors.purple],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(req.applicantName),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.applicantName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Registro: ${req.cardNumber ?? "Pendente"}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
