import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Campo visual/local para dados protegidos com Mostrar/Ocultar.
///
/// Desbloqueio real por senha/biometria será tratado em frente futura de segurança.
class CampoDadoProtegidoToggle extends StatefulWidget {
  final String label;
  final String valorVisivel;
  final String valorOculto;
  final IconData? icon;
  final bool iniciarVisivel;
  final String? semanticsLabel;

  const CampoDadoProtegidoToggle({
    super.key,
    required this.label,
    required this.valorVisivel,
    required this.valorOculto,
    this.icon,
    this.iniciarVisivel = false,
    this.semanticsLabel,
  });

  @override
  State<CampoDadoProtegidoToggle> createState() => _CampoDadoProtegidoToggleState();
}

class _CampoDadoProtegidoToggleState extends State<CampoDadoProtegidoToggle> {
  late bool _visivel;

  @override
  void initState() {
    super.initState();
    _visivel = widget.iniciarVisivel;
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = DsCores.dadosProtegidos.accent;

    return Semantics(
      label: widget.semanticsLabel ?? 'Campo protegido ${widget.label}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rótulo/Label com o ícone de proteção
            Row(
              children: [
                Icon(
                  widget.icon ?? PhosphorIconsRegular.lock,
                  size: 13,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.label,
                    style: DsTipografia.bodySmall.copyWith(
                      color: DsCores.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Valor e botão de alternar visibilidade
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _visivel ? widget.valorVisivel : widget.valorOculto,
                    style: DsTipografia.body.copyWith(
                      color: _visivel ? DsCores.textPrimary : accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _visivel = !_visivel;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _visivel
                            ? PhosphorIconsRegular.eyeSlash
                            : PhosphorIconsRegular.eye,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _visivel ? 'Ocultar' : 'Mostrar',
                        style: DsTipografia.bodySmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
