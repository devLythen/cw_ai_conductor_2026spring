import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'rust/service.dart';
import 'src/rust/types.dart';
import 'src/rust/error.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustService.instance.init();
  runApp(const WinBsodExpertApp());
}

// ─── Window controls (Linux frameless) ───────────────────────────────────────

const _windowChannel = MethodChannel('winbsod/window');
void _winMinimize() => _windowChannel.invokeMethod('minimize');
void _winMaximize() => _windowChannel.invokeMethod('maximize');
void _winClose() => _windowChannel.invokeMethod('close');
void _winStartDrag() => _windowChannel.invokeMethod('startDrag');

// ─── Theme constants ─────────────────────────────────────────────────────────

class _AppTheme {
  _AppTheme._();

  static final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F7DFF),
    brightness: Brightness.dark,
  );

  // Scaffold background – darker than default Material You surface
  static const Color bg = Color(0xFF070B14);

  // Surface layers derived from scheme
  static Color get surface => scheme.surface;
  static Color get card => scheme.surfaceContainerHigh;
  static Color get cardBorder => scheme.outlineVariant;

  // Brand colors
  static Color get accent => scheme.primary;

  // Semantic — kept explicit for meaning
  static const Color green = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static Color get red => scheme.error;

  // Text
  static Color get textPrimary => scheme.onSurface;
  static Color get textSecondary => scheme.onSurfaceVariant;

  static ThemeData get darkTheme {
    final cs = scheme;
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.withValues(alpha: 0.2),
        side: BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(fontSize: 13, color: textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: cs.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textTheme: TextTheme(
        titleLarge:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge:
            TextStyle(color: accent, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textSecondary),
      ),
      dividerColor: cardBorder,
      useMaterial3: true,
    );
  }
}

// ─── App root ────────────────────────────────────────────────────────────────

class WinBsodExpertApp extends StatelessWidget {
  const WinBsodExpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WinBSOD Expert',
      theme: _AppTheme.darkTheme,
      home: const DiagnosisPage(),
    );
  }
}

// ─── Backward-chaining engine ────────────────────────────────────────────────

/// Node in a backward-chaining proof tree.
class _BackwardNode {
  final String factId;
  final bool satisfied;
  final String? ruleId;
  final String? ruleName;
  final List<_BackwardNode> children;

  const _BackwardNode({
    required this.factId,
    this.satisfied = false,
    this.ruleId,
    this.ruleName,
    this.children = const [],
  });
}

/// Result of a backward-chaining query.
class _BackwardResult {
  final String goalFactId;
  final String goalLabel;
  final _BackwardNode? proofTree;
  final List<String> neededEvidence;
  final List<String> satisfiedEvidence;

  const _BackwardResult({
    required this.goalFactId,
    required this.goalLabel,
    this.proofTree,
    this.neededEvidence = const [],
    this.satisfiedEvidence = const [],
  });

  bool get isProvable => proofTree != null;
  bool get isFullySatisfied => neededEvidence.isEmpty;
}

/// Backward chaining over the production rule set.
///
/// Given a goal fact ID (e.g. "cause:driver_conflict"), the current set of
/// selected evidence IDs, and all production rules, returns a [_BackwardResult]
/// containing the proof tree and evidence status.
_BackwardResult _backwardChain(
  String goal,
  Set<String> knownFacts,
  List<RuleView> rules, {
  Set<String>? visited,
  int depth = 0,
}) {
  visited ??= {};
  if (depth > 20) {
    return _BackwardResult(goalFactId: goal, goalLabel: goal, proofTree: null);
  }

  final applicable = rules.where((r) => r.conclusion == goal).toList();

  if (applicable.isEmpty) {
    final satisfied = knownFacts.contains(goal);
    return _BackwardResult(
      goalFactId: goal,
      goalLabel: goal,
      proofTree: _BackwardNode(factId: goal, satisfied: satisfied),
      neededEvidence: satisfied ? [] : [goal],
      satisfiedEvidence: satisfied ? [goal] : [],
    );
  }

  applicable.sort((a, b) {
    const ranks = {'high': 3, 'medium': 2, 'low': 1};
    return (ranks[b.confidence] ?? 0).compareTo(ranks[a.confidence] ?? 0);
  });
  final rule = applicable.first;

  final children = <_BackwardNode>[];
  final needed = <String>[];
  final satisfied = <String>[];

  for (final premise in rule.premises) {
    if (visited.contains(premise)) continue;
    final sub = _backwardChain(
      premise,
      knownFacts,
      rules,
      visited: {...visited, goal},
      depth: depth + 1,
    );
    if (sub.proofTree != null) children.add(sub.proofTree!);
    needed.addAll(sub.neededEvidence);
    satisfied.addAll(sub.satisfiedEvidence);
  }

  return _BackwardResult(
    goalFactId: goal,
    goalLabel: goal,
    proofTree: _BackwardNode(
      factId: goal,
      satisfied: needed.isEmpty,
      ruleId: rule.id,
      ruleName: rule.name,
      children: children,
    ),
    neededEvidence: needed.toSet().toList(),
    satisfiedEvidence: satisfied.toSet().toList(),
  );
}


/// Proof tree display for backward chaining result.
class _BackwardProofTree extends StatelessWidget {
  final _BackwardResult result;
  final Set<String> selectedEvidence;
  const _BackwardProofTree({
    required this.result,
    required this.selectedEvidence,
  });

  @override
  Widget build(BuildContext context) {
    if (result.proofTree == null) {
      return Text('无法为此目标构建证明树',
          style: TextStyle(color: _AppTheme.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status line
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: result.isFullySatisfied
                ? _AppTheme.green.withValues(alpha: 0.12)
                : _AppTheme.amber.withValues(alpha: 0.1),
            border: Border.all(
              color: result.isFullySatisfied
                  ? _AppTheme.green.withValues(alpha: 0.3)
                  : _AppTheme.amber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.isFullySatisfied
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 16,
                color: result.isFullySatisfied
                    ? _AppTheme.green
                    : _AppTheme.amber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.isFullySatisfied
                      ? '所选证据可证明此结论'
                      : '还需要 ${result.neededEvidence.length} 项证据才能证明此结论',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: result.isFullySatisfied
                        ? _AppTheme.green
                        : _AppTheme.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Proof tree
        _buildNode(result.proofTree!, 0),
        // Needed evidence
        if (result.neededEvidence.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('缺少的证据：',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: result.neededEvidence.toSet().map((e) {
              final opt = _lookupEvidence(e);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: _AppTheme.amber.withValues(alpha: 0.3)),
                  color: _AppTheme.amber.withValues(alpha: 0.08),
                ),
                child: Text(opt ?? e,
                    style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildNode(_BackwardNode node, int depth) {
    final evidence = RustService.instance.evidenceOptions();
    final suffix = node.satisfied ? ' ✓' : '';
    String label = node.factId;
    for (final e in evidence) {
      if (e.id == node.factId) {
        label = e.label;
        break;
      }
    }
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (node.ruleId != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _AppTheme.accent.withValues(alpha: 0.15),
                  ),
                  child: Text('[${node.ruleId}]',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _AppTheme.accent,
                          fontFamily: 'monospace')),
                ),
              if (node.ruleId != null) const SizedBox(width: 6),
              Icon(
                node.satisfied
                    ? Icons.check_circle
                    : (node.children.isEmpty
                        ? Icons.radio_button_unchecked
                        : Icons.arrow_right),
                size: 14,
                color: node.satisfied
                    ? _AppTheme.green
                    : _AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$label$suffix',
                  style: TextStyle(
                    fontSize: 12,
                    color: node.satisfied
                        ? _AppTheme.green
                        : _AppTheme.textPrimary,
                    fontWeight:
                        node.satisfied ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (node.ruleName != null && node.ruleName != label)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text('via ${node.ruleName}',
                  style: TextStyle(
                      fontSize: 10, color: _AppTheme.textSecondary)),
            ),
          ...node.children.map((c) => _buildNode(c, depth + 1)),
        ],
      ),
    );
  }
}

String? _lookupEvidence(String factId) {
  try {
    for (final e in RustService.instance.evidenceOptions()) {
      if (e.id == factId) return e.label;
    }
  } catch (_) {}
  return null;
}

/// Full-page animated isometric conveyor background.
class _BackgroundDecorations extends StatefulWidget {
  const _BackgroundDecorations();

  @override
  State<_BackgroundDecorations> createState() => _BackgroundDecorationsState();
}

class _BackgroundDecorationsState extends State<_BackgroundDecorations>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ConveyorBackgroundPainter(_controller.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeltProjector {
  final Offset a;
  final Offset u;
  final Offset v;
  final Offset w = const Offset(0, -1);
  final double length3D;
  late final Offset viewDirLocal;

  _BeltProjector(this.a, Offset b)
      : length3D = _calcL3d(a, b),
        u = _calcU(a, b),
        v = _calcV(a, b) {
    final d = b - a;
    if (length3D > 0) {
      final uy = (d.dy / sy) / length3D;
      final vy = d.dx / length3D;
      viewDirLocal = Offset(-uy, -vy);
    } else {
      viewDirLocal = Offset.zero;
    }
  }

  static const double sy = 0.45; // 调整视角：更小的值会使得视角更低，包裹和传送带更立体

  static double _calcL3d(Offset a, Offset b) {
    final d = b - a;
    return math.sqrt(d.dx * d.dx + (d.dy / sy) * (d.dy / sy));
  }

  static Offset _calcU(Offset a, Offset b) {
    final d = b - a;
    final l3d = _calcL3d(a, b);
    if (l3d == 0) return Offset.zero;
    return d / l3d;
  }

  static Offset _calcV(Offset a, Offset b) {
    final d = b - a;
    final l3d = _calcL3d(a, b);
    if (l3d == 0) return Offset.zero;
    return Offset(-d.dy / sy, d.dx * sy) / l3d;
  }

  Offset project(double x, double y, double z) {
    return a + u * x + v * y + w * z;
  }
}

class _ConveyorBackgroundPainter extends CustomPainter {
  final double t;
  const _ConveyorBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Horizontal belt: moved lower ──
    final hA = Offset(-140, size.height * 0.79);
    final hB = Offset(size.width + 140, size.height * 0.70);
    // ── Vertical belt: lower-left → upper-right, more horizontal ──
    final vA = Offset(size.width * 0.28, size.height + 140);
    final vB = Offset(size.width * 0.55, -140);

    _drawBelt(canvas, hA, hB, 64, t);
    _drawBelt(canvas, vA, vB, 56, (t + 0.34) % 1.0);
  }

  void _drawBelt(
    Canvas canvas,
    Offset a,
    Offset b,
    double width,
    double phase,
  ) {
    final proj = _BeltProjector(a, b);
    if (proj.length3D == 0) return;

    final halfW = width / 2;

    final beltFill = Paint()
      ..color = _AppTheme.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final beltGlow = Paint()
      ..color = _AppTheme.accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.4;
    final hatchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.2;
    final pkgTop = Paint()
      ..color = const Color(0xFF6B9FFF)
      ..style = PaintingStyle.fill;
    final pkgSideA = Paint()
      ..color = const Color(0xFF3D6BCF)
      ..style = PaintingStyle.fill;
    final pkgSideB = Paint()
      ..color = const Color(0xFF2A509E)
      ..style = PaintingStyle.fill;
    final pkgStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pLeft0 = proj.project(0, -halfW, 0);
    final pLeft1 = proj.project(proj.length3D, -halfW, 0);
    final pRight0 = proj.project(0, halfW, 0);
    final pRight1 = proj.project(proj.length3D, halfW, 0);

    final beltPath = Path()
      ..moveTo(pLeft0.dx, pLeft0.dy)
      ..lineTo(pLeft1.dx, pLeft1.dy)
      ..lineTo(pRight1.dx, pRight1.dy)
      ..lineTo(pRight0.dx, pRight0.dy)
      ..close();

    canvas.drawPath(beltPath, beltGlow);
    canvas.drawPath(beltPath, beltFill);
    canvas.drawLine(pLeft0, pLeft1, edgePaint);
    canvas.drawLine(pRight0, pRight1, edgePaint);

    // Continuous travel distance
    const cycleDist = 272.0;
    final travel = phase * cycleDist;

    // Texture lines
    const hatchStep = 68.0;
    for (double x = -travel - hatchStep; x <= proj.length3D + cycleDist; x += hatchStep) {
      if (x < 0 || x > proj.length3D) continue; // Optional clip to belt ends
      final hLeft = proj.project(x, -halfW * 0.78, 0);
      final hRight = proj.project(x, halfW * 0.78, 0);
      canvas.drawLine(hLeft, hRight, hatchPaint);
    }

    // Packages
    const pkgSpacing = 272.0;
    for (double x = -travel + 136.0; x < proj.length3D + cycleDist; x += pkgSpacing) {
      if (x < -60 || x > proj.length3D + 60) continue;
      _drawPackage(canvas, proj, x, pkgTop, pkgSideA, pkgSideB, pkgStroke);
    }
  }

  void _drawPackage(
    Canvas canvas,
    _BeltProjector proj,
    double x,
    Paint topPaint,
    Paint sideAPaint,
    Paint sideBPaint,
    Paint strokePaint,
  ) {
    const L = 18.0;
    const W = 14.0;
    const thick = 14.0;

    final t0 = proj.project(x - L, -W, thick);
    final t1 = proj.project(x + L, -W, thick);
    final t2 = proj.project(x + L,  W, thick);
    final t3 = proj.project(x - L,  W, thick);

    final b0 = proj.project(x - L, -W, 0);
    final b1 = proj.project(x + L, -W, 0);
    final b2 = proj.project(x + L,  W, 0);
    final b3 = proj.project(x - L,  W, 0);

    double signedArea(Offset p0, Offset p1, Offset p2) {
      final v1 = p1 - p0;
      final v2 = p2 - p1;
      return v1.dx * v2.dy - v1.dy * v2.dx;
    }

    final faces = [
      ([t0, t1, t2, t3], topPaint),      // Top
      ([b3, b2, b1, b0], topPaint),      // Bottom
      ([t1, b1, b2, t2], sideBPaint),    // +x
      ([t3, b3, b0, t0], sideBPaint),    // -x
      ([t2, b2, b3, t3], sideAPaint),    // +y
      ([t0, b0, b1, t1], sideAPaint),    // -y
    ];

    final topArea = signedArea(t0, t1, t2);
    
    final backFaces = <(List<Offset>, Paint)>[];
    final frontFaces = <(List<Offset>, Paint)>[];

    for (final face in faces) {
      final pts = face.$1;
      final area = signedArea(pts[0], pts[1], pts[2]);
      if (area * topArea > 0) {
        frontFaces.add(face);
      } else {
        backFaces.add(face);
      }
    }

    void drawFaceList(List<(List<Offset>, Paint)> list, double fillAlpha, double strokeAlpha) {
      for (final face in list) {
        final pts = face.$1;
        final basePaint = face.$2;
        
        final paint = Paint()
          ..color = basePaint.color.withValues(alpha: fillAlpha)
          ..style = PaintingStyle.fill;
          
        final path = Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[2].dx, pts[2].dy)
          ..lineTo(pts[3].dx, pts[3].dy)
          ..close();
          
        canvas.drawPath(path, paint);
        
        final stroke = Paint()
          ..color = strokePaint.color.withValues(alpha: strokeAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokePaint.strokeWidth;
        canvas.drawPath(path, stroke);
      }
    }

    drawFaceList(backFaces, 0.25, 0.15);
    drawFaceList(frontFaces, 0.85, 0.5);
  }

  @override
  bool shouldRepaint(covariant _ConveyorBackgroundPainter old) => old.t != t;
}



/// Frosted-glass panel used throughout diagnosis result cards.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  static const EdgeInsetsGeometry _padding = EdgeInsets.all(12);
  final double radius;
  final Color? accentBorder;
  final List<BoxShadow>? shadows;

  const _GlassPanel({
    required this.child,
    this.radius = 12,
    this.accentBorder,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: _padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: accentBorder ??
                  _AppTheme.cardBorder.withValues(alpha: 0.58),
            ),
            color: _AppTheme.card.withValues(alpha: 0.62),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Animated entry wrapper: fade-in + float-up.
class _ShimmerEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _ShimmerEntry({required this.child, this.delay = Duration.zero});

  @override
  State<_ShimmerEntry> createState() => _ShimmerEntryState();
}

class _ShimmerEntryState extends State<_ShimmerEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const int _entryMs = 450;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _entryMs + widget.delay.inMilliseconds),
    )..forward();
  }



  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _elapsedMs =>
      _ctrl.value * (_entryMs + widget.delay.inMilliseconds);

  double get _progress {
    final p = (_elapsedMs - widget.delay.inMilliseconds) / _entryMs;
    return p.clamp(0.0, 1.0);
  }

  double _curve(Curve c, double t) => c.transform(t.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        if (_elapsedMs < widget.delay.inMilliseconds) {
          return Opacity(opacity: 0, child: widget.child);
        }
        final p = _progress;
        final opacity = _curve(Curves.easeOut, p);
        final y = 16.0 * (1.0 - _curve(Curves.easeOutCubic, p));

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, y),
            child: widget.child,
          ),
        );
      },
    );
  }
}
// ─── Custom top bar (draggable, frameless window controls) ───────────────────

class _CyberTopBar extends StatelessWidget {
  final String? appName;
  final int selectedCount;
  final VoidCallback onRulesTap;

  const _CyberTopBar({
    this.appName,
    required this.selectedCount,
    required this.onRulesTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = _AppTheme.scheme;
    return GestureDetector(
      onPanStart: (_) => _winStartDrag(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.secondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Icon(Icons.memory, color: cs.primary, size: 16),
            ),
            const SizedBox(width: 10),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appName ?? 'WinBSOD Expert',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Windows 蓝屏原因诊断',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Evidence count
            if (selectedCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.3)),
                  color: cs.primary.withValues(alpha: 0.12),
                ),
                child: Text(
                  '$selectedCount',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            const SizedBox(width: 6),
            // Rules button
            IconButton(
              key: const ValueKey('rules_button'),
              icon: Icon(Icons.menu_book,
                  color: cs.onSurfaceVariant, size: 18),
              tooltip: '知识库规则',
              onPressed: onRulesTap,
              splashRadius: 18,
            ),
            const SizedBox(width: 4),
            // Window controls
            _WinControlButton(
              icon: Icons.minimize,
              tooltip: '最小化',
              onTap: _winMinimize,
            ),
            _WinControlButton(
              icon: Icons.crop_square,
              tooltip: '最大化',
              onTap: _winMaximize,
            ),
            _WinControlButton(
              icon: Icons.close,
              tooltip: '关闭',
              onTap: _winClose,
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Window control button (minimize / maximize / close) ─────────────────────

class _WinControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _WinControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WinControlButton> createState() => _WinControlButtonState();
}

class _WinControlButtonState extends State<_WinControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final cs = _AppTheme.scheme;
    if (widget.isClose) {
      fg = _hovered ? cs.onError : cs.onSurfaceVariant;
      bg = _hovered ? cs.error.withValues(alpha: 0.6) : Colors.transparent;
    } else {
      fg = _hovered ? cs.onSurface : cs.onSurfaceVariant;
      bg = _hovered
          ? cs.onSurfaceVariant.withValues(alpha: 0.08)
          : Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: bg,
          ),
          child: Icon(widget.icon, size: 14, color: fg),
        ),
      ),
    );
  }
}
// ─── Main diagnosis page ─────────────────────────────────────────────────────

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  AppInfo? _appInfo;
  List<EvidenceOption> _evidenceOptions = [];
  final Set<String> _selectedEvidence = {};
  DiagnosisResult? _result;
  String? _error;
  bool _loading = false;
  bool _forwardMode = true;
  String? _selectedBackwardGoal;
  _BackwardResult? _backwardResult;
  int _resultVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      _appInfo = RustService.instance.appInfo();
      _evidenceOptions = RustService.instance.evidenceOptions();
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _runDiagnosis() async {
    if (_selectedEvidence.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final request = DiagnosisRequest(
        selectedEvidence: _selectedEvidence.toList(),
      );
      final result = await RustService.instance.diagnoseBlueScreen(request);
      setState(() {
        _result = result;
        _loading = false;
        _resultVersion++;
      });
    } on AppError catch (e) {
      setState(() {
        _error = '[${e.code}] ${e.message}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleEvidence(String id) {
    setState(() {
      if (_selectedEvidence.contains(id)) {
        _selectedEvidence.remove(id);
      } else {
        _selectedEvidence.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedEvidence.clear();
      _result = null;
      _error = null;
      _selectedBackwardGoal = null;
      _backwardResult = null;
      _resultVersion++;
    });
  }

  void _toggleMode() {
    setState(() {
      _forwardMode = !_forwardMode;
      _result = null;
      _error = null;
      _backwardResult = null;
      _selectedBackwardGoal = null;
    });
  }

  void _runBackward() {
    final rules = RustService.instance.ruleViews();
    final result = _backwardChain(_selectedBackwardGoal!, _selectedEvidence, rules);
    setState(() {
      _backwardResult = result;
      _resultVersion++;
    });
  }

  void _showRules() {
    final rules = RustService.instance.ruleViews();
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => RulesPage(rules: rules),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _BackgroundDecorations()),
            Column(
              children: [
                _CyberTopBar(
                  appName: _appInfo?.name,
                  selectedCount: _selectedEvidence.length,
                  onRulesTap: _showRules,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1050.0),
                          child: SizedBox(
                            width: math.max(1050.0, constraints.maxWidth),
                            child: _buildWideLayout(context),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ─── Wide layout (>= 900 px) ───────────────────────────────────────────

  Widget _buildWideLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 440,
                child: _buildEvidencePanel(context),
              ),
              Container(
                width: 1,
                color: _AppTheme.cardBorder,
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
              Expanded(child: _buildResultsPanel(context)),
            ],
          ),
        ),
        _buildBottomActionBar(context),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _AppTheme.cardBorder.withValues(alpha: 0.3)),
            ),
            color: _AppTheme.surface.withValues(alpha: 0.42),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidencePanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _AppTheme.cardBorder.withValues(alpha: 0.56),
              ),
              color: _AppTheme.card.withValues(alpha: 0.52),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Mode switch ──
                  _buildModeSwitch(context),
                  const SizedBox(height: 10),
                  if (_forwardMode) ...[
                    Text(
                      '请选择观察到的证据',
                      style: TextStyle(
                        color: _AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '勾选您遇到的蓝屏现象、错误代码和系统症状',
                      style: TextStyle(
                          color: _AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    _buildEvidenceGrid(context),
                  ] else ...[
                    _buildBackwardGoalList(context),
                  ],
                  const SizedBox(height: 8),
                  if (_error != null) _buildErrorCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('正向'),
          icon: Icon(Icons.arrow_forward, size: 14),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('反向'),
          icon: Icon(Icons.call_split, size: 14),
        ),
      ],
      selected: {_forwardMode},
      onSelectionChanged: (_) => _toggleMode(),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: _AppTheme.accent);
          }
          return BorderSide(color: _AppTheme.cardBorder.withValues(alpha: 0.5));
        }),
      ),
    );
  }

  List<String> _getCauseGoals() {
    try {
      return RustService.instance
          .ruleViews()
          .map((r) => r.conclusion)
          .where((c) => c.startsWith('cause:'))
          .toSet()
          .toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }

  static const _goalLabels = <String, String>{
    'cause:driver_conflict': '驱动冲突/驱动损坏',
    'cause:memory_fault': '内存故障',
    'cause:disk_corruption': '磁盘或文件系统损坏',
    'cause:overheat': '过热保护触发',
    'cause:overheat_or_power': '过热或电源不稳定',
    'cause:update_issue': 'Windows 更新问题',
    'cause:malware': '恶意软件或病毒感染',
    'cause:power_management': '电源管理/ACPI 异常',
    'cause:cpu_instability': 'CPU 供电不稳/降压过度',
    'cause:unknown': '未知原因',
  };

  Widget _buildBackwardGoalList(BuildContext context) {
    final goals = _getCauseGoals();
    if (goals.isEmpty) {
      return Text('未找到可用目标',
          style: TextStyle(color: _AppTheme.textSecondary, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择要证明的目标',
          style: TextStyle(
            color: _AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '系统将反向推导需要收集的证据',
          style: TextStyle(
              color: _AppTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        ...goals.map((goal) {
          final label = _goalLabels[goal] ?? goal;
          final selected = _selectedBackwardGoal == goal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                _selectedBackwardGoal = goal;
                _backwardResult = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? _AppTheme.accent
                        : _AppTheme.cardBorder,
                  ),
                  color: selected
                      ? _AppTheme.accent.withValues(alpha: 0.14)
                      : _AppTheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selected
                          ? _AppTheme.accent
                          : _AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected
                                    ? _AppTheme.accent
                                    : _AppTheme.textSecondary,
                              )),
                          Text(goal,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _AppTheme.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultsPanel(BuildContext context) {
    final hasForwardResult = _result != null;
    final hasBackwardResult = _backwardResult != null;
    
    Widget content;
    if (_forwardMode && hasForwardResult) {
      content = _buildResultsContent(context);
    } else if (!_forwardMode && hasBackwardResult) {
      content = _buildBackwardResultsContent(context);
    } else {
      content = _buildEmptyResults(context);
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    final hint = _forwardMode ? '选择证据后点击"开始诊断"' : '选择目标后点击"反向推理"';
    return SizedBox.expand(
      key: const ValueKey('empty'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search,
                size: 40,
                color: _AppTheme.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 10),
            Text(
              hint,
              style: TextStyle(
                  color: _AppTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent(BuildContext context) {
    return SizedBox.expand(
      key: ValueKey('results_$_resultVersion'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildWarnings(context),
            ..._buildConclusions(context),
            ..._buildTraces(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackwardResultsContent(BuildContext context) {
    if (_backwardResult == null) return const SizedBox.shrink();
    final result = _backwardResult!;
    return SizedBox.expand(
      key: ValueKey('backward_results_$_resultVersion'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '反向推理结果',
            style: TextStyle(
              color: _AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _ShimmerEntry(
            child: _GlassPanel(
              radius: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('目标: ${result.goalFactId}',
                      style: TextStyle(
                          fontSize: 11,
                          color: _AppTheme.textSecondary,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  _BackwardProofTree(
                    result: result,
                    selectedEvidence: _selectedEvidence,
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // ─── Shared widgets ─────────────────────────────────────────────────────
  Widget _buildActionRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildClearButton(context),
        const SizedBox(width: 8),
        _buildDiagnoseButton(context),
      ],
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final enabled = _selectedEvidence.isNotEmpty || _result != null || _backwardResult != null;
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: enabled ? _clearSelection : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppTheme.textSecondary,
          disabledForegroundColor:
              _AppTheme.textSecondary.withValues(alpha: 0.35),
          side: BorderSide(
            color: enabled
                ? _AppTheme.cardBorder
                : _AppTheme.cardBorder.withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('清除', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildDiagnoseButton(BuildContext context) {
    final forwardEnabled = _selectedEvidence.isNotEmpty && !_loading;
    final backwardEnabled = _selectedBackwardGoal != null && !_loading;
    final enabled = _forwardMode ? forwardEnabled : backwardEnabled;
    final onPressed = _forwardMode
        ? (enabled ? _runDiagnosis : null)
        : (enabled ? _runBackward : null);
    final label = _forwardMode
        ? (_loading ? '推理中...' : '开始诊断')
        : (_loading ? '推理中...' : '反向推理');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: enabled ? 1.0 : 0.98),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SizedBox(
        height: 40,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black54,
                  ),
                )
              : Icon(_forwardMode ? Icons.search : Icons.call_split),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildEvidenceGrid(BuildContext context) {
    final groups = <String, List<EvidenceOption>>{};
    for (final opt in _evidenceOptions) {
      groups.putIfAbsent(opt.category, () => []).add(opt);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                entry.key,
                style: TextStyle(
                  color: _AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: entry.value.map((opt) {
                final selected = _selectedEvidence.contains(opt.id);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          selected ? _AppTheme.accent : _AppTheme.cardBorder,
                      width: 1,
                    ),
                    color: selected
                        ? _AppTheme.accent.withValues(alpha: 0.14)
                        : _AppTheme.surface,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _AppTheme.accent.withValues(alpha: 0.08),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _toggleEvidence(opt.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            child: Opacity(
                              opacity: selected ? 1 : 0,
                              child: Icon(Icons.check_circle,
                                  size: 14, color: _AppTheme.accent),
                            ),
                          ),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? _AppTheme.accent
                                  : _AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Widget> _buildWarnings(BuildContext context) {
    if (_result!.warnings.isEmpty) return [];
    return [
      ..._result!.warnings.asMap().entries.map(
        (entry) => _ShimmerEntry(
          delay: Duration(milliseconds: entry.key * 60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GlassPanel(
              radius: 8,
              accentBorder: _AppTheme.amber.withValues(alpha: 0.3),
              shadows: const [],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber,
                      color: _AppTheme.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.value,
                        style: TextStyle(
                            fontSize: 13, color: _AppTheme.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildConclusions(BuildContext context) {
    if (_result!.conclusions.isEmpty) {
      return [
        _GlassPanel(
          radius: 8,
          shadows: const [],
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: _AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '未能推导出明确原因，请提供更多证据后重试。',
                  style: TextStyle(
                      color: _AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ];
    }

    return [
      Text(
        '诊断结论',
        style: TextStyle(
          color: _AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      ..._result!.conclusions.asMap().entries.map((entry) {
        final idx = entry.key;
        final c = entry.value;
        return _ShimmerEntry(
          delay: Duration(milliseconds: idx * 80),
          child: _buildConclusionCard(context, c),
        );
      }),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildConclusionCard(BuildContext context, DiagnosisConclusion c) {
    final severityColor = switch (c.severity) {
      'critical' => _AppTheme.red,
      'warning' => _AppTheme.amber,
      _ => _AppTheme.accent,
    };
    final confidenceIcon = switch (c.confidence) {
      'high' => Icons.sentiment_satisfied,
      'medium' => Icons.sentiment_neutral,
      _ => Icons.sentiment_dissatisfied,
    };
    final confidenceLabel = switch (c.confidence) {
      'high' => '高置信度',
      'medium' => '中等置信度',
      _ => '低置信度',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _GlassPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: severityColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report,
                          color: severityColor, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.title,
                          style: TextStyle(
                            color: _AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _AppTheme.cardBorder
                                .withValues(alpha: 0.65),
                          ),
                          color: _AppTheme.surface.withValues(alpha: 0.42),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(confidenceIcon,
                                size: 12,
                                color: _AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              confidenceLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c.explanation,
                      style: TextStyle(
                          fontSize: 13,
                          color: _AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    '建议处理步骤：',
                    style: TextStyle(
                      color: _AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...c.recommendations.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _AppTheme.textSecondary)),
                          Expanded(
                            child: Text(r,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _AppTheme.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTraces(BuildContext context) {
    if (_result!.traces.isEmpty) return [];
    return [
      Text(
        '推理链（正向推理记录）',
        style: TextStyle(
          color: _AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      _GlassPanel(
        radius: 8,
        accentBorder: _AppTheme.green.withValues(alpha: 0.2),
        shadows: const [],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _result!.traces.map((t) {
            final facts = t.matchedFacts.join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '[${t.ruleId}] ${t.ruleName}\n'
                '  IF $facts\n'
                '  THEN ${t.producedFact}',
                style: TextStyle(
                  fontSize: 12,
                  color: _AppTheme.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildErrorCard(BuildContext context) {
    return _GlassPanel(
      radius: 8,
      accentBorder: _AppTheme.red.withValues(alpha: 0.3),
      shadows: const [],
      child: Row(
        children: [
          Icon(Icons.error, color: _AppTheme.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!,
                style:
                    TextStyle(color: _AppTheme.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Rules page ──────────────────────────────────────────────────────────────

class RulesPage extends StatelessWidget {
  final List<RuleView> rules;
  const RulesPage({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    final cs = _AppTheme.scheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Custom top bar
                GestureDetector(
                  onPanStart: (_) => _winStartDrag(),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      border: Border(
                        bottom:
                            BorderSide(color: cs.outlineVariant, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: cs.onSurfaceVariant, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '知识库规则',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: cs.primary.withValues(alpha: 0.3)),
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            '${rules.length}',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _WinControlButton(
                          icon: Icons.minimize,
                          tooltip: '最小化',
                          onTap: _winMinimize,
                        ),
                        _WinControlButton(
                          icon: Icons.crop_square,
                          tooltip: '最大化',
                          onTap: _winMaximize,
                        ),
                        _WinControlButton(
                          icon: Icons.close,
                          tooltip: '关闭',
                          onTap: _winClose,
                          isClose: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final r = rules[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: _AppTheme.cardBorder),
                          color: _AppTheme.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    color: _AppTheme.accent
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: Text(
                                    '[${r.id}]',
                                    style: TextStyle(
                                      color: _AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: TextStyle(
                                      color: _AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    border: Border.all(
                                        color: _AppTheme.cardBorder),
                                  ),
                                  child: Text(
                                    r.confidence,
                                    style: TextStyle(
                                      color: _AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'IF  ${r.premises.join("  ∧  ")}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'THEN  ${r.conclusion}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _AppTheme.accent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r.explanation,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _AppTheme.textSecondary),
                            ),
                          ],
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
