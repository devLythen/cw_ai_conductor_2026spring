import 'package:flutter_test/flutter_test.dart';
import 'package:cw_ai_conductor_2026spring/main.dart';
import 'package:cw_ai_conductor_2026spring/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('App shows custom top bar and core elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WinBsodExpertApp());
    await tester.pumpAndSettle();
    // Title in custom top bar
    expect(find.textContaining('WinBSOD'), findsOneWidget);
    // Custom top bar subtitle
    expect(find.text('Windows 蓝屏原因诊断'), findsOneWidget);
    // Evidence section exists
    expect(find.text('请选择观察到的证据'), findsOneWidget);
  });
}
