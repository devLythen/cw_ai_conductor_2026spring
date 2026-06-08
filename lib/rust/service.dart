import 'package:cw_ai_conductor_2026spring/src/rust/api.dart' as bridge;
import 'package:cw_ai_conductor_2026spring/src/rust/frb_generated.dart';
import 'package:cw_ai_conductor_2026spring/src/rust/types.dart';

/// Service wrapper around the flutter_rust_bridge generated layer.
///
/// Flutter UI calls this — never the generated code directly.
/// This isolates UI from codegen changes and provides a stable Dart API.
class RustService {
  static final RustService _instance = RustService._();
  static RustService get instance => _instance;
  RustService._();

  bool _initialized = false;

  /// Initialize the Rust bridge. Must be called once before any other method.
  ///
  /// Pass [api] in tests to provide a mock implementation via [RustLib.initMock].
  Future<void> init({RustLibApi? api}) async {
    if (_initialized) return;
    if (api != null) {
      RustLib.initMock(api: api);
    } else {
      await RustLib.init();
    }
    _initialized = true;
  }

  /// Returns application metadata from the Rust core.
  AppInfo appInfo() {
    _ensureInit();
    return bridge.appInfo();
  }

  /// Submits a task to the Rust core for processing (legacy).
  Future<TaskResponse> processTask(TaskRequest request) async {
    _ensureInit();
    return bridge.processTask(request: request);
  }

  // -------------------------------------------------------------------------
  // WinBSOD Expert
  // -------------------------------------------------------------------------

  /// Returns all available evidence options for the diagnosis UI.
  List<EvidenceOption> evidenceOptions() {
    _ensureInit();
    return bridge.evidenceOptions();
  }

  /// Returns all production rules for knowledge-base browsing.
  List<RuleView> ruleViews() {
    _ensureInit();
    return bridge.ruleViews();
  }

  /// Runs forward-chaining diagnosis from user-selected evidence.
  Future<DiagnosisResult> diagnoseBlueScreen(DiagnosisRequest request) async {
    _ensureInit();
    return bridge.diagnoseBlueScreen(request: request);
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('RustService not initialized. Call init() first.');
    }
  }
}
