import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/widgets/account_change_summary_card.dart';

void main() {
  group('AccountChangeSummaryCard Widget Tests', () {
    AccountChangeRequest createMockRequest({
      required AccountChangeStatus status,
      required AccountChangeType type,
      AccountChangeCivilDate? holderDeadlineDueDate,
      DateTime? closedAt,
    }) {
      return AccountChangeRequest(
        id: 'test-id',
        protocolNumber: 'AC-20260612-A1B2C3D4',
        type: type,
        status: status,
        newValueMasked: 'new***@domain.com',
        createdAt: DateTime.parse('2026-06-12T15:00:00Z'),
        updatedAt: DateTime.parse('2026-06-12T15:30:00Z'),
        holderDeadlineDueDate: holderDeadlineDueDate,
        closedAt: closedAt,
      );
    }

    Widget buildTestableWidget(Widget child, {double textScaleFactor = 1.0}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
          child: Scaffold(body: child),
        ),
      );
    }

    group('3. TESTES DE PRAZO (Visibilidade do prazo do titular)', () {
      testWidgets('Prazo aparece em waitingDocumentReplacement', (
        WidgetTester tester,
      ) async {
        final req = createMockRequest(
          status: AccountChangeStatus.waitingDocumentReplacement,
          type: AccountChangeType.cpf,
          holderDeadlineDueDate: AccountChangeCivilDate(
            year: 2026,
            month: 6,
            day: 25,
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        expect(
          find.text('Prazo para sua ação: até 25/06/2026.'),
          findsOneWidget,
        );
      });

      testWidgets('Prazo aparece em waitingHolderConfirmation', (
        WidgetTester tester,
      ) async {
        final req = createMockRequest(
          status: AccountChangeStatus.waitingHolderConfirmation,
          type: AccountChangeType.email,
          holderDeadlineDueDate: AccountChangeCivilDate(
            year: 2026,
            month: 6,
            day: 25,
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        expect(
          find.text('Prazo para sua ação: até 25/06/2026.'),
          findsOneWidget,
        );
      });

      // Parametrização defensiva para todos os status onde o prazo NÃO pode aparecer
      final nonDeadlineStatuses = [
        AccountChangeStatus.underReview,
        AccountChangeStatus.applying,
        AccountChangeStatus.applicationFailed,
        AccountChangeStatus.completed,
        AccountChangeStatus.rejectedByAdmin,
        AccountChangeStatus.cancelledByHolder,
        AccountChangeStatus.expired,
        AccountChangeStatus.unknown,
      ];

      for (final status in nonDeadlineStatuses) {
        testWidgets(
          'Prazo NÃO aparece no status ${status.name} mesmo com payload de data',
          (WidgetTester tester) async {
            final req = createMockRequest(
              status: status,
              type: AccountChangeType.cpf,
              holderDeadlineDueDate: AccountChangeCivilDate(
                year: 2026,
                month: 6,
                day: 25,
              ),
            );

            await tester.pumpWidget(
              buildTestableWidget(
                AccountChangeSummaryCard(request: req, onTap: () {}),
              ),
            );

            expect(
              find.text('Prazo para sua ação: até 25/06/2026.'),
              findsNothing,
            );
          },
        );
      }
    });

    group('4. TESTES DE ENCERRAMENTO (Data de Encerramento no histórico)', () {
      testWidgets('Completed com closedAt mostra "Concluída em"', (
        WidgetTester tester,
      ) async {
        final req = createMockRequest(
          status: AccountChangeStatus.completed,
          type: AccountChangeType.email,
          closedAt: DateTime.parse('2026-06-13T12:00:00Z'),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        expect(find.text('Concluída em 13/06/2026'), findsOneWidget);
      });

      testWidgets('RejectedByAdmin com closedAt mostra "Encerrada em"', (
        WidgetTester tester,
      ) async {
        final req = createMockRequest(
          status: AccountChangeStatus.rejectedByAdmin,
          type: AccountChangeType.cpf,
          closedAt: DateTime.parse('2026-06-13T12:00:00Z'),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        expect(find.text('Encerrada em 13/06/2026'), findsOneWidget);
      });

      testWidgets('CancelledByHolder com closedAt mostra "Encerrada em"', (
        WidgetTester tester,
      ) async {
        final req = createMockRequest(
          status: AccountChangeStatus.cancelledByHolder,
          type: AccountChangeType.email,
          closedAt: DateTime.parse('2026-06-13T12:00:00Z'),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        expect(find.text('Encerrada em 13/06/2026'), findsOneWidget);
      });

      testWidgets('Expired com closedAt mostra "Encerrada em"', (
        WidgetTester tester,
      ) async {
        final req = createMockRequest(
          status: AccountChangeStatus.expired,
          type: AccountChangeType.cpf,
          closedAt: DateTime.parse('2026-06-13T12:00:00Z'),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        expect(find.text('Encerrada em 13/06/2026'), findsOneWidget);
      });

      // Parametrização defensiva para todos os status ativos onde o encerramento NÃO pode aparecer
      final activeStatuses = [
        AccountChangeStatus.underReview,
        AccountChangeStatus.waitingDocumentReplacement,
        AccountChangeStatus.waitingHolderConfirmation,
        AccountChangeStatus.applying,
        AccountChangeStatus.applicationFailed,
        AccountChangeStatus.unknown,
      ];

      for (final status in activeStatuses) {
        testWidgets('Encerramento NÃO aparece no status ativo ${status.name}', (
          WidgetTester tester,
        ) async {
          final req = createMockRequest(
            status: status,
            type: AccountChangeType.cpf,
            closedAt: DateTime.parse('2026-06-13T12:00:00Z'),
          );

          await tester.pumpWidget(
            buildTestableWidget(
              AccountChangeSummaryCard(request: req, onTap: () {}),
            ),
          );

          expect(find.textContaining('Concluída em'), findsNothing);
          expect(find.textContaining('Encerrada em'), findsNothing);
        });
      }
    });

    group('5. TESTE REAL DE 360DP E FONTE AMPLIADA', () {
      testWidgets('Nenhum overflow com largura de 360dp e escala de fonte 1.5', (
        WidgetTester tester,
      ) async {
        final view = tester.view;
        final initialPhysicalSize = view.physicalSize;
        final initialDevicePixelRatio = view.devicePixelRatio;

        addTearDown(() {
          view.physicalSize = initialPhysicalSize;
          view.devicePixelRatio = initialDevicePixelRatio;
        });

        // Configura viewport equivalente a 360dp lógicos
        view.physicalSize = const Size(360, 800);
        view.devicePixelRatio = 1.0;

        final longLabelStatuses = [
          AccountChangeStatus.waitingDocumentReplacement,
          AccountChangeStatus.applying,
          AccountChangeStatus.applicationFailed,
        ];

        for (final status in longLabelStatuses) {
          bool tapped = false;
          final req = createMockRequest(
            status: status,
            type: AccountChangeType.cpf,
            holderDeadlineDueDate: AccountChangeCivilDate(
              year: 2026,
              month: 6,
              day: 25,
            ),
          );

          await tester.pumpWidget(
            buildTestableWidget(
              AccountChangeSummaryCard(
                request: req,
                onTap: () {
                  tapped = true;
                },
              ),
              textScaleFactor: 1.5,
            ),
          );

          // Aguarda layouts estabilizarem
          await tester.pumpAndSettle();

          // Garante que não houve exceções ou overflows de RenderFlex
          expect(tester.takeException(), isNull);
          expect(find.byType(AccountChangeSummaryCard), findsOneWidget);

          // Chevron do Phosphor caretRight deve permanecer renderizado na linha superior
          expect(find.byIcon(PhosphorIconsRegular.caretRight), findsOneWidget);

          // Prazo de ação deve estar presente sem truncamento/ellipsis se status for waitingDocumentReplacement
          if (status == AccountChangeStatus.waitingDocumentReplacement) {
            final textFinder = find.text(
              'Prazo para sua ação: até 25/06/2026.',
            );
            expect(textFinder, findsOneWidget);
            final textWidget = tester.widget<Text>(textFinder);
            expect(textWidget.overflow, isNot(equals(TextOverflow.ellipsis)));
          }

          // Confirma que a ação de clique (onTap) permanece funcional
          await tester.tap(find.byType(AccountChangeSummaryCard));
          expect(tapped, isTrue);
        }
      });
    });

    group('6. TESTE DA ÁRVORE SEMÂNTICA ÚNICA', () {
      testWidgets(
        'Garante exatamente um nó de botão e sem duplicidade de textos internos',
        (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();

          final req = createMockRequest(
            status: AccountChangeStatus.waitingHolderConfirmation,
            type: AccountChangeType.cpf,
            holderDeadlineDueDate: AccountChangeCivilDate(
              year: 2026,
              month: 6,
              day: 25,
            ),
          );

          await tester.pumpWidget(
            buildTestableWidget(
              AccountChangeSummaryCard(request: req, onTap: () {}),
            ),
          );

          // Confirma existência de exatamente 1 nó semântico com a label correta de acessibilidade
          final expectedLabel =
              'Solicitação de alteração de CPF. Status: CONFIRMAÇÃO PENDENTE. Prazo para sua ação até 25 de junho de 2026. Toque para abrir detalhes.';

          final SemanticsNode node = tester.getSemantics(
            find.byType(AccountChangeSummaryCard),
          );
          final SemanticsData data = node.getSemanticsData();

          expect(data.label, expectedLabel);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(data.flagsCollection.isButton, isTrue);

          // Garante que os textos e widgets internos (ocultados pelo ExcludeSemantics) não criam nós duplicados na árvore semântica
          // (ExcludeSemantics faz com que o nó de semântica do card não tenha nenhum filho na árvore semântica).
          expect(node.childrenCount, 0);

          handle.dispose();
        },
      );

      testWidgets('Sem prazo a label não anuncia a data', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        final req = createMockRequest(
          status: AccountChangeStatus.underReview,
          type: AccountChangeType.cpf,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AccountChangeSummaryCard(request: req, onTap: () {}),
          ),
        );

        final expectedLabel =
            'Solicitação de alteração de CPF. Status: EM ANÁLISE. Toque para abrir detalhes.';

        final SemanticsNode node = tester.getSemantics(
          find.byType(AccountChangeSummaryCard),
        );
        final SemanticsData data = node.getSemanticsData();

        expect(data.label, expectedLabel);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(node.childrenCount, 0);

        handle.dispose();
      });
    });
  });
}
