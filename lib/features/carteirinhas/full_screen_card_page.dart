import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math';

import '../../core/constants/colors.dart';
import '../../core/design_system_v2/design_system_v2.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import 'widgets/digital/digital_card_widget.dart';

class FullScreenCardPage extends StatefulWidget {
  final List<Member> members;
  final Map<String, DigitalCard> cardsByMemberId;
  final int initialMemberIndex;

  const FullScreenCardPage({
    super.key,
    required this.members,
    required this.cardsByMemberId,
    this.initialMemberIndex = 0,
  });

  @override
  State<FullScreenCardPage> createState() => _FullScreenCardPageState();
}

class _FullScreenCardPageState extends State<FullScreenCardPage>
    with SingleTickerProviderStateMixin {
  late int _selectedMemberIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isBackVisible = false;
  bool _showCpf = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberIndex = widget.initialMemberIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isBackVisible) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isBackVisible = !_isBackVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.members[_selectedMemberIndex];
    final card = widget.cardsByMemberId[member.id]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradiente de Fundo e Grade
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF0E2A52), AppColors.background],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return _buildLandscapeLayout(member, card);
                }
                return _buildPortraitLayout(member, card);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(Member member, DigitalCard card) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildMemberSelector(),
                const SizedBox(height: 24),
                _buildCardDisplay(member, card),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIconsRegular.deviceMobile,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vire o celular para visualizar melhor',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildControls(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout(Member member, DigitalCard card) {
    return Stack(
      children: [
        // A carteirinha digital centralizada, ocupando o máximo de espaço seguro
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 80.0,
            ),
            child: _buildCardDisplay(member, card),
          ),
        ),

        // Botão de fechar/voltar no canto superior esquerdo (com margem segura)
        Positioned(top: 16, left: 16, child: _buildLandscapeCloseButton()),

        // Botão compacto de alternar membro flutuante à direita (se houver mais de 1)
        if (widget.members.length > 1)
          Positioned(
            bottom: 80,
            right: 16,
            child: _buildLandscapeSwitchMemberButton(),
          ),

        // Botão de virar frente/verso (compacto, apenas com ícone) flutuante à direita
        Positioned(bottom: 16, right: 16, child: _buildLandscapeFlipButton()),
      ],
    );
  }

  Widget _buildLandscapeCloseButton() {
    return Semantics(
      label: 'Fechar visualização da carteirinha',
      button: true,
      child: Tooltip(
        message: 'Fechar',
        child: Container(
          decoration: BoxDecoration(
            color: DsCores.glass.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: DsCores.perigo.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: DsCores.perigo.accent.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(
                PhosphorIconsRegular.x,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeFlipButton() {
    final label = _isBackVisible ? 'Ver frente' : 'Ver verso';
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: DsCores.glass.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: DsCores.carteirinha.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: DsCores.carteirinha.accent.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(
                PhosphorIconsRegular.arrowsLeftRight,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _flipCard,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeSwitchMemberButton() {
    if (widget.members.length <= 1) return const SizedBox.shrink();

    return Semantics(
      label: 'Ver próxima carteirinha',
      button: true,
      child: Tooltip(
        message: 'Ver próxima carteirinha',
        child: Container(
          decoration: BoxDecoration(
            color: DsCores.glass.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: DsCores.dependente.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: DsCores.dependente.accent.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(
                PhosphorIconsRegular.userSwitch,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _selectedMemberIndex =
                      (_selectedMemberIndex + 1) % widget.members.length;
                  _showCpf = false;
                  if (_isBackVisible) _flipCard();
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardDisplay(Member member, DigitalCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 450,
              height: 450 / 1.58,
              child: HeroMode(
                enabled:
                    MediaQuery.of(context).orientation == Orientation.portrait,
                child: Hero(
                  tag: 'card_${member.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final value = _animation.value;
                        final isBack = value > 0.5;

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(value * pi),
                          alignment: Alignment.center,
                          child: isBack
                              ? Transform(
                                  transform: Matrix4.identity()..rotateY(pi),
                                  alignment: Alignment.center,
                                  child: DigitalCardWidget(
                                    member: member,
                                    card: card,
                                    showBack: true,
                                    enableParallax: false,
                                    enableEntryAnimation: false,
                                    showCpf: _showCpf,
                                    onToggleCpf: () =>
                                        setState(() => _showCpf = !_showCpf),
                                  ),
                                )
                              : DigitalCardWidget(
                                  member: member,
                                  card: card,
                                  showBack: false,
                                  enableParallax: false,
                                  enableEntryAnimation: false,
                                  showCpf: _showCpf,
                                  onToggleCpf: () =>
                                      setState(() => _showCpf = !_showCpf),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.x,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Hero(
            tag: 'app_logo_mini',
            child: Image.asset(
              'assets/images/conectea_logo.png',
              height: 32,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 48), // Espaçador para equilíbrio visual
        ],
      ),
    );
  }

  Widget _buildMemberSelector({EdgeInsetsGeometry? padding}) {
    if (widget.members.length <= 1) return const SizedBox.shrink();

    final items = widget.members.map((member) {
      final Color statusColor = DsTokenStatus.active.primary;
      const String statusLabel = 'Ativa';

      return DsMembroCarrosselItem(
        id: member.id,
        name: member.displayName.split(' ').first,
        initials: member.initials,
        statusLabel: statusLabel,
        statusColor: statusColor,
        paletteSeed: member.userId,
      );
    }).toList();

    final String selectedId = widget.members[_selectedMemberIndex].id;

    final Widget carrossel = DsMembrosCarrossel(
      items: items,
      selectedId: selectedId,
      onItemSelected: (id) {
        final index = widget.members.indexWhere((m) => m.id == id);
        if (index != -1 && index != _selectedMemberIndex) {
          setState(() {
            _selectedMemberIndex = index;
            _showCpf = false;
            if (_isBackVisible) _flipCard();
          });
        }
      },
      sectionTitle: '${widget.members.length} membros',
    );

    if (padding != null) {
      return Padding(padding: padding, child: carrossel);
    }

    return carrossel;
  }

  Widget _buildControls({bool compact = false}) {
    return Column(
      children: [
        DsBotao(
          label: _isBackVisible ? 'VER FRENTE' : 'VER VERSO',
          onPressed: _flipCard,
          variante: DsBotaoVariante.acao,
          token: DsCores.carteirinha,
          icon: PhosphorIconsRegular.arrowsLeftRight,
          fullWidth: false,
        ),
        SizedBox(height: compact ? 12 : 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'USE O BOTÃO PARA GIRAR A CARTEIRINHA',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
