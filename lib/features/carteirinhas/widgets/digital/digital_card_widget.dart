import 'package:flutter/material.dart';
import 'digital_card_motion_wrapper.dart';
import 'digital_card_front.dart';
import 'digital_card_back.dart';

import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';

class DigitalCardWidget extends StatefulWidget {
  final DigitalCard? card;
  final Member member;
  final bool showBack;
  final bool enableParallax;
  final bool enableEntryAnimation;
  final bool isStatic;
  final bool? showCpf;
  final VoidCallback? onToggleCpf;
  final String? statusOverride;

  const DigitalCardWidget({
    super.key,
    this.card,
    required this.member,
    this.showBack = false,
    this.enableParallax = true,
    this.enableEntryAnimation = true,
    this.isStatic = false,
    this.showCpf,
    this.onToggleCpf,
    this.statusOverride,
  });

  @override
  State<DigitalCardWidget> createState() => _DigitalCardWidgetState();
}

class _DigitalCardWidgetState extends State<DigitalCardWidget> {
  bool _internalShowCpf = false;

  bool get _effectiveShowCpf => widget.showCpf ?? _internalShowCpf;
  
  void _handleToggleCpf() {
    if (widget.onToggleCpf != null) {
      widget.onToggleCpf?.call();
    } else {
      setState(() => _internalShowCpf = !_internalShowCpf);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStatic) {
      return AspectRatio(
        aspectRatio: 1.58,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 450,
              height: 450 / 1.58,
              child: widget.showBack
                  ? DigitalCardBack(
                      member: widget.member, 
                      card: widget.card,
                      showCpf: _effectiveShowCpf,
                      onToggleCpf: _handleToggleCpf,
                    )
                  : DigitalCardFront(
                      member: widget.member,
                      card: widget.card,
                      statusOverride: widget.statusOverride,
                    ),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.58, // Proporção padrão de cartão de crédito
      child: DigitalCardMotionWrapper(
        enabled: widget.enableParallax,
        enableEntryAnimation: widget.enableEntryAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 450, // Largura Premium
                  height: 450 / 1.58,
                  child: widget.showBack
                      ? DigitalCardBack(
                          member: widget.member, 
                          card: widget.card,
                          showCpf: _effectiveShowCpf,
                          onToggleCpf: _handleToggleCpf,
                        )
                      : DigitalCardFront(
                          member: widget.member,
                          card: widget.card,
                          statusOverride: widget.statusOverride,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
