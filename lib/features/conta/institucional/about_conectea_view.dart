import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela interna informativa: Sobre o ConeCTEA.
class AboutConecteaView extends StatelessWidget {
  const AboutConecteaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DsBotaoVoltar(
                        onPressed: () => Navigator.pop(context),
                        token: DsCores.institucional,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Sobre o ConeCTEA',
                        style: DsTipografia.pageTitle.copyWith(
                          color: DsCores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entenda a finalidade do app e os limites da carteirinha comunitária.',
                        style: DsTipografia.pageSubtitle.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bloco 1 — O que é o ConeCTEA
                      _buildBlock(
                        icon: PhosphorIconsRegular.info,
                        title: 'O que é o ConeCTEA',
                        text:
                            'O ConeCTEA é um app comunitário criado para apoiar a organização de informações, solicitações, carteirinhas comunitárias, comunicações e ações da Família TEA Bauru.',
                      ),
                      const SizedBox(height: 16),

                      // Bloco 2 — Para que serve
                      _buildBlock(
                        icon: PhosphorIconsRegular.circlesThreePlus,
                        title: 'Para que serve',
                        text:
                            'O app ajuda a centralizar recursos importantes para a comunidade, como cadastro, carteirinha comunitária, acompanhamento de solicitações, notificações, suporte, privacidade e informações institucionais.',
                      ),
                      const SizedBox(height: 16),

                      // Bloco 3 — O que o ConeCTEA não é
                      _buildBlock(
                        icon: PhosphorIconsRegular.xCircle,
                        title: 'O que o ConeCTEA não é',
                        text:
                            'O ConeCTEA não é órgão público, serviço governamental, serviço médico, clínica, ferramenta de diagnóstico ou documento oficial.',
                        token: DsCores.alerta,
                      ),
                      const SizedBox(height: 16),

                      // Bloco 4 — Sobre a carteirinha
                      _buildBlock(
                        icon: PhosphorIconsRegular.identificationCard,
                        title: 'Sobre a carteirinha',
                        text:
                            'A carteirinha comunitária tem uso interno e comunitário. Ela não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico, documento civil ou serviço público.',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Botão final
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: DsBotao(
                    label: 'Entendi',
                    onPressed: () => Navigator.pop(context),
                    variante: DsBotaoVariante.acao,
                    token: DsCores.institucional,
                    icon: PhosphorIconsRegular.check,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock({
    required IconData icon,
    required String title,
    required String text,
    DsCorVisual token = DsCores.institucional,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(icon: icon, accentColor: token.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: DsTipografia.body.copyWith(
              color: DsCores.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
