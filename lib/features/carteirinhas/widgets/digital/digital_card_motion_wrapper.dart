import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Um wrapper que adiciona efeito de movimento 3D (parallax) baseado nos sensores do dispositivo
/// ou na posição do mouse (em desktops).
class DigitalCardMotionWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool enableEntryAnimation;

  const DigitalCardMotionWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.enableEntryAnimation = true,
  });

  @override
  State<DigitalCardMotionWrapper> createState() =>
      _DigitalCardMotionWrapperState();
}

class _DigitalCardMotionWrapperState extends State<DigitalCardMotionWrapper>
    with SingleTickerProviderStateMixin {
  double _pitch = 0.0;
  double _yaw = 0.0;
  StreamSubscription? _accelerometerSubscription;
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de Entrada
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation =
        Tween<double>(
          begin: widget.enableEntryAnimation ? 0.95 : 1.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _opacityAnimation = Tween<double>(
      begin: widget.enableEntryAnimation ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeIn));
    _entryController.forward();

    // Sensor Parallax - usando giroscópio ou acelerômetro
    if (widget.enabled) {
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        setState(() {
          // Limita os ângulos para evitar extremos e inverte para uma sensação natural
          _pitch = (event.y * 0.03).clamp(-0.15, 0.15);
          _yaw = (-event.x * 0.03).clamp(-0.15, 0.15);
        });
      });
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (!widget.enabled) return;
        // Usa inclinação do mouse apenas se sensores não estiverem ativos ou em desktop/web
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          final localPosition = event.localPosition;

          // Calcula a posição relativa (-1.0 a 1.0)
          final relX = (localPosition.dx / size.width) * 2 - 1;
          final relY = (localPosition.dy / size.height) * 2 - 1;

          setState(() {
            _yaw = (relX * 0.1).clamp(-0.15, 0.15);
            _pitch = (-relY * 0.1).clamp(-0.15, 0.15);
          });
        }
      },
      onExit: (_) {
        setState(() {
          _yaw = 0.0;
          _pitch = 0.0;
        });
      },
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: TweenAnimationBuilder(
                tween: Tween<Offset>(
                  begin: Offset.zero,
                  end: Offset(_yaw, _pitch),
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, Offset offset, child) {
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspectiva
                    ..rotateX(offset.dy)
                    ..rotateY(offset.dx);

                  return Transform(
                    transform: matrix,
                    alignment: FractionalOffset.center,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
