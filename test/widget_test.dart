import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cw_ai_conductor_2026spring/main.dart';
import 'package:cw_ai_conductor_2026spring/rust/service.dart';
import 'package:cw_ai_conductor_2026spring/src/rust/frb_generated.dart';
import 'package:cw_ai_conductor_2026spring/src/rust/types.dart';

class _MockApi extends RustLibApi {
  @override
  AppInfo crateApiAppInfo() {
    return const AppInfo(
      name: 'WinBSOD Expert (test)',
      version: '0.1.0',
      rustVersion: '1.95.0',
    );
  }

  @override
  List<EvidenceOption> crateApiEvidenceOptions() {
    return const [
      EvidenceOption(
        id: 'bugcheck:0xD1',
        label: '\u84dd\u5c4f\u4ee3\u7801 0xD1',
        category: '\u84dd\u5c4f\u4ee3\u7801',
        description: 'DRIVER_IRQL_NOT_LESS_OR_EQUAL',
      ),
      EvidenceOption(
        id: 'bucheck:0x1A',
        label: '\u84dd\u5c4f\u4ee3\u7801 0x1A',
        category: '\u84dd\u5c4f\u4ee3\u7801',
        description: 'MEMORY_MANAGEMENT',
      ),
      EvidenceOption(
        id: 'symptom:random_crash',
        label: '\u968f\u673a\u84dd\u5c4f',
        category: '\u5d29\u6e83\u573a\u666f',
        description: '\u7cfb\u7edf\u968f\u673a\u84dd\u5c4f',
      ),
    ];
  }

  @override
  List<RuleView> crateApiRuleViews() {
    return const [
      RuleView(
        id: 'R1',
        name: '\u6d4b\u8bd5\u89c4\u5219',
        premises: ['bugcheck:0xD1'],
        conclusion: 'cause:driver_conflict',
        confidence: 'high',
        explanation: '\u6d4b\u8bd5\u89e3\u91ca',
      ),
    ];
  }

  @override
  Future<DiagnosisResult> crateApiDiagnoseBlueScreen({
    required DiagnosisRequest request,
  }) async {
    final hasD1 = request.selectedEvidence.contains('bugcheck:0xD1');
    return DiagnosisResult(
      conclusions: hasD1
          ? [
              const DiagnosisConclusion(
                id: 'cause:driver_conflict',
                title: '\u9a71\u52a8\u51b2\u7a81/\u9a71\u52a8\u635f\u574f',
                confidence: 'high',
                severity: 'critical',
                explanation:
                    '[R1] \u6d4b\u8bd5\u89c4\u5219\uff1a\u6d4b\u8bd5\u89e3\u91ca \u2192 cause:driver_conflict',
                recommendations: ['\u91cd\u65b0\u5b89\u88c5\u9a71\u52a8'],
              ),
            ]
          : [],
      inferredFacts: [],
      traces: hasD1
          ? [
              const RuleTrace(
                ruleId: 'R1',
                ruleName: '\u6d4b\u8bd5\u89c4\u5219',
                matchedFacts: ['bugcheck:0xD1'],
                producedFact: 'cause:driver_conflict',
                explanation: '\u6d4b\u8bd5\u89e3\u91ca',
              ),
            ]
          : [],
      warnings: hasD1
          ? []
          : ['\u672a\u547d\u4e2d\u4efb\u4f55\u89c4\u5219'],
    );
  }

  // Legacy methods
  @override
  Future<void> crateApiInitApp() async {}

  @override
  Future<TaskResponse> crateApiProcessTask({
    required TaskRequest request,
  }) async {
    return TaskResponse(
      taskId: request.id,
      result: 'processed: ${request.payload}',
      status: 'ok',
    );
  }
}

void main() {
  setUp(() async {
    await RustService.instance.init(api: _MockApi());
  });

  testWidgets('App shows custom top bar with title and window controls',
      (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('WinBSOD Expert (test)'), findsOneWidget);
    expect(find.text('Windows \u84dd\u5c4f\u539f\u56e0\u8bca\u65ad'),
        findsOneWidget);
    // Rules button icon is present
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
    // Window control buttons are present
    expect(find.byIcon(Icons.minimize), findsOneWidget);
    expect(find.byIcon(Icons.crop_square), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('Evidence chips are displayed in forward mode', (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'), findsOneWidget);
    expect(find.text('\u84dd\u5c4f\u4ee3\u7801 0x1A'), findsOneWidget);
    expect(find.text('\u968f\u673a\u84dd\u5c4f'), findsOneWidget);
  });

  testWidgets('Select evidence and run forward diagnosis', (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Tap the 0xD1 evidence chip
    await tester.tap(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'));
    await tester.pump(const Duration(milliseconds: 600));

    // Tap the diagnose button
    await tester.tap(find.text('\u5f00\u59cb\u8bca\u65ad'));
    await tester.pump(const Duration(milliseconds: 800));

    // Should show driver conflict conclusion
    expect(find.text('\u9a71\u52a8\u51b2\u7a81/\u9a71\u52a8\u635f\u574f'),
        findsOneWidget);
    // Should show recommendation
    expect(find.text('\u91cd\u65b0\u5b89\u88c5\u9a71\u52a8'), findsOneWidget);
    // Should show trace
    expect(find.textContaining('R1'), findsWidgets);
  });

  testWidgets('Forward diagnosis with no matching evidence shows warning',
      (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Select random_crash only (no match in our mock)
    await tester.tap(find.text('\u968f\u673a\u84dd\u5c4f'));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('\u5f00\u59cb\u8bca\u65ad'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('\u672a\u547d\u4e2d\u4efb\u4f55\u89c4\u5219'),
        findsOneWidget);
  });

  testWidgets('Clear button clears selection and results', (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Select evidence
    await tester.tap(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'));
    await tester.pump(const Duration(milliseconds: 600));

    // Run diagnosis
    await tester.tap(find.text('\u5f00\u59cb\u8bca\u65ad'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('\u9a71\u52a8\u51b2\u7a81/\u9a71\u52a8\u635f\u574f'),
        findsOneWidget);

    // Scroll to the clear button (now at bottom)
    final clearBtn = find.text('\u6e05\u9664');
    expect(clearBtn, findsOneWidget);
    await tester.ensureVisible(clearBtn);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(clearBtn);
    await tester.pump(const Duration(milliseconds: 400));
    // Results should be cleared, empty hint shown
    expect(find.textContaining('\u9009\u62e9\u8bc1\u636e\u540e\u70b9\u51fb'),
        findsOneWidget);

    // Verify evidence panel still has the chips (forward mode)
    expect(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'), findsOneWidget);
  });

  testWidgets('Rule browsing page opens', (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));
    // Open rules page
    await tester.tap(find.byKey(const ValueKey('rules_button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('\u6d4b\u8bd5\u89c4\u5219'), findsOneWidget);
    expect(find.textContaining('R1'), findsWidgets);
  });

  testWidgets('Wide-screen layout shows both panels', (tester) async {
    // Set a wide viewport
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });

    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Evidence panel heading and results placeholder both visible
    expect(find.text('\u8bf7\u9009\u62e9\u89c2\u5bdf\u5230\u7684\u8bc1\u636e'),
        findsOneWidget);
    expect(find.textContaining('\u9009\u62e9\u8bc1\u636e\u540e\u70b9\u51fb'),
        findsOneWidget);
  });

  testWidgets('Forward/backward mode switch exists and defaults to forward',
      (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Mode switch visible with forward selected
    expect(find.text('\u6b63\u5411'), findsOneWidget);
    expect(find.text('\u53cd\u5411'), findsOneWidget);

    // Evidence chips visible (forward mode default)
    expect(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'), findsOneWidget);
  });

  testWidgets('Switch to backward mode shows goal selection', (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to backward mode
    await tester.tap(find.text('\u53cd\u5411'));
    await tester.pump(const Duration(milliseconds: 400));

    // Evidence chips should be gone
    expect(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'), findsNothing);

    // Goal selection should be visible
    expect(find.text('\u9009\u62e9\u8981\u8bc1\u660e\u7684\u76ee\u6807'),
        findsOneWidget);

    // Our mock R1 has conclusion 'cause:driver_conflict'
    // which maps to '\u9a71\u52a8\u51b2\u7a81/\u9a71\u52a8\u635f\u574f'
    expect(find.text('\u9a71\u52a8\u51b2\u7a81/\u9a71\u52a8\u635f\u574f'),
        findsOneWidget);

    // The button text should now say '\u53cd\u5411\u63a8\u7406'
    expect(find.text('\u53cd\u5411\u63a8\u7406'), findsOneWidget);
  });

  testWidgets('Backward mode: select goal and run inference shows proof tree',
      (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to backward mode
    await tester.tap(find.text('\u53cd\u5411'));
    await tester.pump(const Duration(milliseconds: 400));

    // Select the driver_conflict goal
    await tester.tap(find.text('\u9a71\u52a8\u51b2\u7a81/\u9a71\u52a8\u635f\u574f'));
    await tester.pump(const Duration(milliseconds: 400));

    // Tap the backward inference button
    await tester.tap(find.text('\u53cd\u5411\u63a8\u7406'));
    await tester.pump(const Duration(milliseconds: 800));

    // Should show the proof containing R1
    expect(find.textContaining('R1'), findsOneWidget);

    // Should show backward results heading
    expect(find.text('\u53cd\u5411\u63a8\u7406\u7ed3\u679c'), findsOneWidget);
  });

  testWidgets('Switching back to forward mode restores evidence chips',
      (tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to backward
    await tester.tap(find.text('\u53cd\u5411'));
    await tester.pump(const Duration(milliseconds: 400));

    // Switch back to forward
    await tester.tap(find.text('\u6b63\u5411'));
    await tester.pump(const Duration(milliseconds: 400));

    // Evidence chips should be back
    expect(find.text('\u84dd\u5c4f\u4ee3\u7801 0xD1'), findsOneWidget);
    // Button should say '\u5f00\u59cb\u8bca\u65ad' again
    expect(find.text('\u5f00\u59cb\u8bca\u65ad'), findsOneWidget);
  });
}
