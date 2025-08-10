import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/whisperfire_models.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

/// PremiumOutputCard
/// A faithful Flutter port of the React "MySnitchAICards" premium card.
/// - Animated metric bars
/// - Risk gradient border
/// - Evidence bullets, tactic confidence bar
/// - Copyable reply with style badge
/// - Safety + Ambiguity callouts
/// - Pattern cycle + timeline receipts
///
/// Usage:
///   PremiumOutputCard(analysis: _analysis!, tab: 'scan' | 'comeback' | 'pattern')
class PremiumOutputCard extends StatelessWidget {
  final WhisperfireResponse analysis;
  final String tab; // 'scan' | 'comeback' | 'pattern'
  final VoidCallback? onShare; // optional hook
  const PremiumOutputCard({
    super.key,
    required this.analysis,
    required this.tab,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final data = analysis.data!;
    final isPattern = tab == 'pattern';
    final isComeback = tab == 'comeback';
    final icon = _tabIcon(tab, color: Colors.white);

    return Stack(
      children: [
        // soft border glow based on risk
        Container(
          decoration: BoxDecoration(
            gradient: _riskBorderGradient(data.safety.riskLevel),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header with share
                  _HeaderRow(
                    title: _cardTitle(tab),
                    sublabel: 'Live Analysis',
                    icon: icon,
                    onShare: onShare ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share coming soon!'),
                              backgroundColor: AppColors.primaryBlue,
                            ),
                          );
                        },
                    timestamp: _timestampForFooter(),
                    prognosis: isPattern ? (data.pattern.prognosis ?? '') : null,
                    riskLevel: data.safety.riskLevel,
                  ),
                  const SizedBox(height: 16),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBar(
                          label: 'Red Flag',
                          value: data.metrics.redFlag,
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricBar(
                          label: 'Certainty',
                          value: data.metrics.certainty,
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.lightBlueAccent],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricBar(
                          label: 'Viral',
                          value: data.metrics.viralPotential,
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.deepPurpleAccent],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Headline + Core Take
                  LayoutBuilder(builder: (_, __) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _GlowBox(
                                child: Text(
                                  data.headline,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937), // slate-800
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CardSurface(
                                title: '💡  Core Take',
                                titleColor: const Color(0xFF3730A3), // indigo-800
                                child: Text(
                                  data.coreTake,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E3A8A), // indigo-900
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  // Dynamic sections by tab
                  if (tab == 'scan') _ScanSections(data: data),
                  if (isComeback) _ComebackSections(data: data),
                  if (isPattern) _PatternSections(data: data),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB)), // slate-200
                  const SizedBox(height: 12),

                  // Footer branding
                  _FooterRow(timestamp: _timestampForFooter()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _cardTitle(String tab) {
    switch (tab) {
      case 'scan':
        return 'Scan Analysis';
      case 'comeback':
        return 'Comeback';
      case 'pattern':
        return 'Pattern Analysis';
      default:
        return 'Analysis';
    }
  }

  String _timestampForFooter() {
    // you can wire real time if desired
    return TimeOfDay.now().format(const TimeOfDayFormat.H_colon_mm);
  }

  Widget _tabIcon(String tab, {Color color = Colors.white}) {
    final size = 18.0;
    switch (tab) {
      case 'scan':
        return Icon(Icons.bolt, size: size, color: color); // Zap
      case 'comeback':
        return Icon(Icons.gps_fixed, size: size, color: color); // Target
      case 'pattern':
        return Icon(Icons.trending_up, size: size, color: color); // TrendingUp
      default:
        return Icon(Icons.bolt, size: size, color: color);
    }
  }

  Gradient _riskBorderGradient(String level) {
    // mimic React: LOW green, MOD amber, HIGH orange-red, CRITICAL red-pink
    switch (level) {
      case 'CRITICAL':
        return const LinearGradient(colors: [Colors.red, Colors.pinkAccent]);
      case 'HIGH':
        return const LinearGradient(colors: [Colors.orange, Colors.red]);
      case 'MODERATE':
        return const LinearGradient(colors: [Colors.amber, Colors.orange]);
      case 'LOW':
      default:
        return const LinearGradient(colors: [Colors.green, Colors.teal]);
    }
  }
}

/* -------------------------- Sections -------------------------- */

class _ScanSections extends StatelessWidget {
  final WhisperfireOutput data;
  const _ScanSections({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 2 columns on large, one on small – we stack vertical for phone
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                _PremiumSection(
                  title: '📄 Evidence Receipts',
                  child: _AnimatedBullets(items: data.receipts),
                ),
                const SizedBox(height: 12),
                _PremiumSection(
                  title: '🎯 Identified Tactic',
                  child: _TacticConfidence(
                    label: data.tactic.label,
                    confidence: data.tactic.confidence,
                  ),
                ),
                const SizedBox(height: 12),
                _PremiumSection(
                  title: '⚡ Power Play',
                  child: _SoftCallout(
                    text: data.powerPlay,
                    bg: const Color(0xFFFFF7ED), // orange-50
                    border: const Color(0xFFFDE68A), // amber-ish border
                    textColor: const Color(0xFF7C2D12), // orange-900
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(children: [
                _PremiumSection(
                  title: '💬 AI-Generated Response',
                  child: _CopyableResponse(
                    text: data.suggestedReply.text,
                    style: data.suggestedReply.style,
                  ),
                ),
                const SizedBox(height: 12),
                _PremiumSection(
                  title: '🛡️ Safety Assessment',
                  child: _SafetyNote(
                    level: data.safety.riskLevel,
                    text: data.safety.notes,
                  ),
                ),
                const SizedBox(height: 12),
                _PremiumSection(
                  title: '⚠️ Ambiguity',
                  child: _AmbiguitySection(
                    warning: data.ambiguity.warning,
                    missing: data.ambiguity.missingEvidence,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComebackSections extends StatelessWidget {
  final WhisperfireOutput data;
  const _ComebackSections({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left
        Expanded(
          child: Column(
            children: [
              _ComebackShowcase(
                roastLine: data.suggestedReply.text,
                altLine: null, // backend doesn't provide alt_line; keep null
                style: data.suggestedReply.style,
              ),
              const SizedBox(height: 12),
              _PremiumSection(
                title: '⚡ Power Play',
                child: _SoftCallout(
                  text: data.powerPlay,
                  bg: const Color(0xFFFFF7ED),
                  border: const Color(0xFFFDE68A),
                  textColor: const Color(0xFF7C2D12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // right
        Expanded(
          child: Column(
            children: [
              _PremiumSection(
                title: '📄 Evidence Receipts',
                child: _AnimatedBullets(items: data.receipts),
              ),
              const SizedBox(height: 12),
              _PremiumSection(
                title: '🛡️ Safety Assessment',
                child: _SafetyNote(
                  level: data.safety.riskLevel,
                  text: data.safety.notes,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatternSections extends StatelessWidget {
  final WhisperfireOutput data;
  const _PatternSections({required this.data});

  @override
  Widget build(BuildContext context) {
    // next_moves in backend is a short string; we’ll split it into bullets if possible
    final actions = _splitToBullets(data.nextMoves);

    return Column(
      children: [
        _CollapsibleSection(
          title: '🔄 Behavioral Cycle',
          child: _CycleVisualization(text: data.pattern.cycle ?? ''),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                _PremiumSection(
                  title: '📄 Timeline Evidence',
                  child: _TimelineReceipts(items: data.receipts),
                ),
                const SizedBox(height: 12),
                _PremiumSection(
                  title: '⚡ Power Play',
                  child: _SoftCallout(
                    text: data.powerPlay,
                    bg: const Color(0xFFFFF7ED),
                    border: const Color(0xFFFDE68A),
                    textColor: const Color(0xFF7C2D12),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(children: [
                Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        label: 'Psychological Motives',
                        value: data.motives,
                        icon: '🧠',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightCard(
                        label: 'Targeting Behavior',
                        value: data.targeting,
                        icon: '🎯',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PremiumSection(
                  title: '➡️ Recommended Actions',
                  child: (actions.isNotEmpty)
                      ? _ActionItems(items: actions)
                      : _AnimatedBullets(items: [data.nextMoves]),
                ),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PremiumSection(
                title: '🛡️ Risk Assessment',
                child: _SafetyNote(
                  level: data.safety.riskLevel,
                  text: data.safety.notes,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PremiumSection(
                title: '⚠️ Ambiguity',
                child: _AmbiguitySection(
                  warning: data.ambiguity.warning,
                  missing: data.ambiguity.missingEvidence,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<String> _splitToBullets(String s) {
    final raw = s.trim();
    if (raw.isEmpty) return const [];
    // try splitting on newline / • / ; / . (short sentences)
    final parts = raw
        .split(RegExp(r'[\n•;]|(?<=[.])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.length <= 1 ? [] : parts.take(6).toList();
  }
}

/* -------------------------- Header / Footer -------------------------- */

class _HeaderRow extends StatelessWidget {
  final String title;
  final String sublabel;
  final Widget icon;
  final VoidCallback onShare;
  final String timestamp;
  final String? prognosis;
  final String riskLevel;
  const _HeaderRow({
    required this.title,
    required this.sublabel,
    required this.icon,
    required this.onShare,
    required this.timestamp,
    required this.riskLevel,
    this.prognosis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF475569)],
                  ).createShader(r),
                  child: const Text(
                    // React shows dynamic title (Scan/Pattern/Comeback)
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 0, // hidden, we show [title] below as normal
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF60A5FA), // blue-400
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280), // slate-500
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.08),
                    Colors.purple.withOpacity(0.08)
                  ],
                ),
                border: Border.all(color: const Color(0xFFBFDBFE).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.share, color: Colors.blue, size: 20),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)], // slate-50 → blue-50
          ),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _RiskChip(level: riskLevel),
            const SizedBox(width: 8),
            if ((prognosis ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  prognosis!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF60A5FA),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ]);
  }
}

class _FooterRow extends StatelessWidget {
  final String timestamp;
  const _FooterRow({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Premium logo (simplified)
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Center(
            child: Icon(Icons.visibility, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'MySnitchAI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ).createShader(Rect.fromLTWH(0, 0, 100, 20)),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Powered by Advanced AI',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.lock, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              'AI-Generated  •  $timestamp',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }
}

/* -------------------------- Primitives -------------------------- */

class _GlowBox extends StatelessWidget {
  final Widget child;
  const _GlowBox({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)], // blue-50 → purple-50
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFBFDBFE).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardSurface extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget child;
  const _CardSurface({
    required this.title,
    required this.titleColor,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFEFF6FF)], // indigo-100 → blue-50
        ),
        border: Border.all(color: const Color(0xFFDDD6FE).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
            child: Text(title),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _PremiumSection({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          child: Text(title),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  const _CollapsibleSection({required this.title, required this.child});
  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _open = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Icon(_open ? Icons.expand_less : Icons.expand_more, size: 22),
          ),
        ]),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _open ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: widget.child,
          ) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _AnimatedBullets extends StatelessWidget {
  final List<String> items;
  const _AnimatedBullets({required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((txt) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  txt,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CopyableResponse extends StatelessWidget {
  final String text;
  final String style; // clipped | one_liner | reverse_uno | screenshot_bait | monologue
  const _CopyableResponse({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    final badge = _styleBadge(style);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE5E7EB)], // slate-50 → slate-200
        ),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        badge,
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied response')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _styleBadge(String style) {
    // tailwind-esque badge palette (approx)
    final map = {
      'clipped': const _BadgeStyle(bg: Color(0xFFF1F5F9), fg: Color(0xFF334155)), // slate
      'one_liner': const _BadgeStyle(bg: Color(0xFFDBEAFE), fg: Color(0xFF1D4ED8)), // blue
      'reverse_uno': const _BadgeStyle(bg: Color(0xFFE9D5FF), fg: Color(0xFF7C3AED)), // purple
      'screenshot_bait': const _BadgeStyle(bg: Color(0xFFFBCFE8), fg: Color(0xFFBE185D)), // pink
      'monologue': const _BadgeStyle(bg: Color(0xFFD1FAE5), fg: Color(0xFF065F46)), // emerald
    };
    final s = map[style] ?? map['clipped']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: s.fg.withOpacity(0.25)),
      ),
      child: Text(
        (style.replaceAll('_', ' ')).toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: s.fg,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;
  const _BadgeStyle({required this.bg, required this.fg});
}

class _SafetyNote extends StatelessWidget {
  final String level; // LOW | MODERATE | HIGH | CRITICAL
  final String text;
  const _SafetyNote({required this.level, required this.text});
  @override
  Widget build(BuildContext context) {
    final isHigh = level == 'HIGH' || level == 'CRITICAL';
    final moderate = level == 'MODERATE';
    final bg = moderate
        ? const Color(0xFFFFFBEB) // amber-50
        : isHigh
            ? const Color(0xFFFFEBEE) // red-50
            : const Color(0xFFF0FDF4); // green-50
    final border = moderate
        ? const Color(0xFFFDE68A) // amber-200
        : isHigh
            ? const Color(0xFFFECACA) // red-200
            : const Color(0xFFBBF7D0); // green-200
    final fg = moderate
        ? const Color(0xFF92400E) // amber-800
        : isHigh
            ? const Color(0xFF991B1B) // red-800
            : const Color(0xFF065F46); // green-800

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHigh)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: fg,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbiguitySection extends StatelessWidget {
  final String? warning;
  final List<String>? missing;
  const _AmbiguitySection({this.warning, this.missing});
  @override
  Widget build(BuildContext context) {
    if ((warning == null || warning!.isEmpty) &&
        (missing == null || missing!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // yellow-50
        border: Border.all(color: const Color(0xFFFDE68A).withOpacity(0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warning != null && warning!.isNotEmpty) ...[
            const Text(
              '⚠️ Ambiguity Warning',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA16207), // amber-700
              ),
            ),
            const SizedBox(height: 6),
            Text(
              warning!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E), // amber-800
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (missing != null && missing!.isNotEmpty) ...[
            const Text(
              'Missing Evidence',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA16207),
              ),
            ),
            const SizedBox(height: 6),
            _AnimatedBullets(items: missing!),
          ],
        ],
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String level; // LOW MODERATE HIGH CRITICAL
  const _RiskChip({required this.level});
  @override
  Widget build(BuildContext context) {
    LinearGradient g;
    switch (level) {
      case 'CRITICAL':
        g = const LinearGradient(colors: [Colors.red, Colors.pink]);
        break;
      case 'HIGH':
        g = const LinearGradient(colors: [Colors.orange, Colors.red]);
        break;
      case 'MODERATE':
        g = const LinearGradient(colors: [Colors.yellow, Colors.orange]);
        break;
      case 'LOW':
      default:
        g = const LinearGradient(colors: [Colors.green, Colors.teal]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: g.colors.last.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const DefaultTextStyle(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
        child: Text(''),
      ),
    );
  }
}

class _MetricBar extends StatefulWidget {
  final String label;
  final int value; // 0-100
  final Gradient gradient;
  const _MetricBar({
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  State<_MetricBar> createState() => _MetricBarState();
}

class _MetricBarState extends State<_MetricBar> {
  double w = 0;
  @override
  void initState() {
    super.initState();
    // slight delay for nicer animation
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => w = widget.value / 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
          Text('${widget.value}%',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
        ],
      ),
      const SizedBox(height: 6),
      LayoutBuilder(builder: (context, c) {
        final maxW = c.maxWidth;
        return Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), // slate-200
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOut,
              width: max(0, maxW * w),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }),
    ]);
  }
}

class _TacticConfidence extends StatelessWidget {
  final String label;
  final int confidence;
  const _TacticConfidence({required this.label, required this.confidence});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
        ),
        border: Border.all(color: const Color(0xFFBFDBFE).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Text(
            '$confidence%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: confidence / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCallout extends StatelessWidget {
  final String text;
  final Color bg;
  final Color border;
  final Color textColor;
  const _SoftCallout({
    required this.text,
    required this.bg,
    required this.border,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: textColor,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ComebackShowcase extends StatelessWidget {
  final String roastLine;
  final String? altLine;
  final String style;
  const _ComebackShowcase({
    required this.roastLine,
    required this.altLine,
    required this.style,
  });
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)], // rose-50 → pink-50
          ),
          border: Border.all(color: const Color(0xFFFECACA).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const Text(
                'PREMIUM ROAST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBE123C), // rose-700
                ),
              ),
            ]),
            // badge reuse
            _CopyableResponse(text: '', style: style)._styleBadge(style),
          ]),
          const SizedBox(height: 8),
          Text(
            '“$roastLine”',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: roastLine));
              // toast
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied roast')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Roast', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      if ((altLine ?? '').isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)], // emerald-50
            ),
            border: Border.all(color: const Color(0xFFA7F3D0).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Softer Alternative',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF047857),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '“$altLine”',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontStyle: FontStyle.italic,
              ),
            ),
          ]),
        ),
      ],
    ]);
  }
}

class _CycleVisualization extends StatelessWidget {
  final String text;
  const _CycleVisualization({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFE0E7FF)], // purple-50 → indigo-100
        ),
        border: Border.all(color: const Color(0xFFE9D5FF).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF374151),
          height: 1.45,
        ),
      ),
    );
  }
}

class _TimelineReceipts extends StatelessWidget {
  final List<String> items;
  const _TimelineReceipts({required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final txt = e.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    txt,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _InsightCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)], // slate-50
        ),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
              letterSpacing: 1.0,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            height: 1.5,
          ),
        ),
      ]),
    );
  }
}

class _ActionItems extends StatelessWidget {
  final List<String> items;
  const _ActionItems({required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final txt = e.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  txt,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
