import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/whisperfire_models.dart';

class PremiumOutputCard extends StatelessWidget {
  final WhisperfireResponse analysis;
  final String tab; // 'scan' | 'comeback' | 'pattern'
  final VoidCallback? onShare;
  final VoidCallback? onCopyJSON;
  final VoidCallback? onDownloadJSON;

  const PremiumOutputCard({
    super.key,
    required this.analysis,
    required this.tab,
    this.onShare,
    this.onCopyJSON,
    this.onDownloadJSON,
  });

  @override
  Widget build(BuildContext context) {
    final data = analysis.data;
    if (data == null) return const SizedBox.shrink();

    final icon = _tabIcon(tab);
    final riskColor = _riskColor(data.safety.riskLevel);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundGray800.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppConstants.xlRadius),
        border: Border.all(color: AppColors.borderGray600, width: 0.5),
      ),
      child: Stack(
        children: [
          // subtle risk glow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      riskColor.withOpacity(0.10),
                      Colors.transparent,
                      riskColor.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.blueCyanGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.blueCyanGradient.createShader(b),
                            child: const Text(
                              'Live Analysis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.headline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _shareButton(),
                  ],
                ),
                const SizedBox(height: 14),

                // Status row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray800,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGray600, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      _riskChip(data.safety.riskLevel),
                      const SizedBox(width: 8),
                      if (tab == 'pattern' && (data.pattern.prognosis?.isNotEmpty ?? false))
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.borderGray600, width: 0.5),
                            ),
                            child: Text(
                              data.pattern.prognosis!,
                              style: TextStyle(
                                color: AppColors.textGray200,
                                fontSize: 12,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _timeNowLabel(),
                            style: TextStyle(
                              color: AppColors.textGray500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Metrics row
                Row(
                  children: [
                    Expanded(child: _MetricBar(label: 'Red Flag', value: data.metrics.redFlag, color: AppColors.dangerRed)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricBar(label: 'Certainty', value: data.metrics.certainty, color: AppColors.primaryBlue)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricBar(label: 'Viral', value: data.metrics.viralPotential, color: AppColors.primaryPurple)),
                  ],
                ),

                const SizedBox(height: 16),

                // Headline + Core take
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _GlowBox(
                        child: Text(
                          data.headline,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: '💡 Core Take',
                  child: Text(
                    data.coreTake,
                    style: TextStyle(color: AppColors.textGray200, fontSize: 14, height: 1.45),
                  ),
                ),

                const SizedBox(height: 16),

                // Dynamic content per tab
                _tabContent(context, data),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCopyJSON,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderGray600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: AppColors.textGray400, size: 16),
                            const SizedBox(width: 8),
                            Text('Copy JSON',
                              style: TextStyle(
                                color: AppColors.textGray400, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDownloadJSON,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderGray600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, color: AppColors.textGray400, size: 16),
                            const SizedBox(width: 8),
                            Text('Download JSON',
                              style: TextStyle(
                                color: AppColors.textGray400, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Branding footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderGray600, width: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _premiumLogo(),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) => AppColors.pinkPurpleGradient.createShader(b),
                                child: const Text(
                                  'MySnitch AI',
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text('Powered by Advanced AI',
                                style: TextStyle(color: AppColors.textGray500, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: AppColors.textGray500),
                          const SizedBox(width: 6),
                          Text('AI-Generated • ${_timeNowLabel()}',
                              style: TextStyle(color: AppColors.textGray500, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabContent(BuildContext context, WhisperfireOutput data) {
    if (tab == 'scan') {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _premSection('📄 Evidence Receipts', _animatedBullets(data.receipts))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _premSection(
                      '🔍 Identified Tactic',
                      Column(
                        children: [
                          _tacticRow(data.tactic.label, data.tactic.confidence),
                          const SizedBox(height: 10),
                          _miniBreakdown(data),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _premSection(
                      '🎭 Power Play',
                      Text(data.powerPlay, style: TextStyle(color: AppColors.textGray200, height: 1.45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _premSection(
                  '🤖 AI-Generated Response',
                  _copyableResponse(text: data.suggestedReply.text, style: data.suggestedReply.style),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _premSection('⚡ Safety Assessment', _safetyNote(data.safety)),
                    const SizedBox(height: 12),
                    if (data.ambiguity.warning != null || (data.ambiguity.missingEvidence?.isNotEmpty ?? false))
                      _premSection('🔍 Ambiguity', _ambiguity(data.ambiguity)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (tab == 'comeback') {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _premSection(
                  '🔥 Premium Roast',
                  _comebackShowcase(
                    roastLine: data.suggestedReply.text,
                    style: data.suggestedReply.style,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _premSection('📄 Evidence Receipts', _animatedBullets(data.receipts)),
                    const SizedBox(height: 12),
                    _premSection('⚡ Safety Assessment', _safetyNote(data.safety)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _premSection('🎭 Power Play',
              Text(data.powerPlay, style: TextStyle(color: AppColors.textGray200, height: 1.45))),
        ],
      );
    }

    // pattern
    return Column(
      children: [
        _premSection(
          '🔄 Behavioral Cycle',
          _cycleVisualization(data.pattern.cycle ?? ''),
          collapsible: false,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _premSection('📊 Timeline Evidence', _timelineReceipts(data.receipts)),
                  const SizedBox(height: 12),
                  _premSection('🎭 Power Play',
                      Text(data.powerPlay, style: TextStyle(color: AppColors.textGray200, height: 1.45))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _insightCard('🧠 Psychological Motives', data.motives)),
                      const SizedBox(width: 12),
                      Expanded(child: _insightCard('🎯 Targeting Behavior', data.targeting)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _premSection('🚀 Recommended Actions', _actionItems([data.nextMoves])),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _premSection('⚠️ Risk Assessment', _safetyNote(data.safety))),
            const SizedBox(width: 12),
            Expanded(child: _premSection('🔍 Ambiguity', _ambiguity(data.ambiguity))),
          ],
        ),
      ],
    );
  }

  // ---------- bits ----------

  Widget _premiumLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.blueCyanGradient,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.backgroundGray800,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            gradient: AppColors.blueCyanGradient,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _shareButton() {
    return GestureDetector(
      onTap: onShare,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray600, width: 0.5),
        ),
        child: Icon(Icons.share, color: AppColors.textGray300, size: 18),
      ),
    );
  }

  IconData _tabIcon(String t) {
    switch (t) {
      case 'comeback': return Icons.bolt_rounded;
      case 'pattern': return Icons.trending_up_rounded;
      default: return Icons.search_rounded;
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'CRITICAL': return AppColors.dangerRed;
      case 'HIGH': return AppColors.dangerRed;
      case 'MODERATE': return AppColors.warningYellow;
      default: return AppColors.successGreen;
    }
  }

  Widget _riskChip(String level) {
    final c = _riskColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.withOpacity(0.6), c.withOpacity(0.35)]),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.7), width: 1),
      ),
      child: Text(
        '$level RISK',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _tacticRow(String label, int confidence) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray600, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Text('$confidence%',
              style: TextStyle(color: AppColors.textGray300, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: confidence.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, val, _) => Stack(
                  children: [
                    Container(height: 6, color: Colors.white.withOpacity(0.08)),
                    FractionallySizedBox(
                      widthFactor: (val / 100).clamp(0, 1),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: AppColors.pinkPurpleGradient,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBreakdown(WhisperfireOutput d) {
    Widget chip(String label, String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray600, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: AppColors.textGray400, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: chip('Motives', d.motives, Icons.psychology)),
            const SizedBox(width: 8),
            Expanded(child: chip('Targeting', d.targeting, Icons.gps_fixed)),
            const SizedBox(width: 8),
            Expanded(child: chip('Power Play', d.powerPlay, Icons.trending_up)),
          ],
        ),
      ],
    );
  }

  Widget _animatedBullets(List<String> items) {
    return Column(
      children: items.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 6, height: 6,
              margin: const EdgeInsets.only(top: 7, right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.blueCyanGradient,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: Text(t, style: TextStyle(color: AppColors.textGray200, height: 1.45)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _copyableResponse({required String text, required String style}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.blueCyanGradient,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                style.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _comebackShowcase({required String roastLine, required String style}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copyableResponse(text: roastLine, style: style),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray600, width: 0.5),
          ),
          child: Text(
            'Softer Alternative: try a gentler variant if needed.',
            style: TextStyle(color: AppColors.textGray400, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _cycleVisualization(String cycle) {
    return _GlowBox(
      child: Text(
        cycle,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
      ),
    );
  }

  Widget _timelineReceipts(List<String> items) {
    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key; final text = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.blueCyanGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: TextStyle(color: AppColors.textGray200, height: 1.45)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _insightCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.blueCyanGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
        ],
      ),
    );
  }

  Widget _actionItems(List<String> items) {
    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key; final t = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.pinkPurpleGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: TextStyle(color: AppColors.textGray200, height: 1.45))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _safetyNote(WhisperfireSafety s) {
    final isHigh = s.riskLevel == 'HIGH' || s.riskLevel == 'CRITICAL';
    final bg = isHigh
        ? AppColors.dangerRed.withOpacity(0.10)
        : s.riskLevel == 'MODERATE'
            ? AppColors.warningYellow.withOpacity(0.10)
            : AppColors.successGreen.withOpacity(0.10);
    final border = isHigh
        ? AppColors.dangerRed.withOpacity(0.30)
        : s.riskLevel == 'MODERATE'
            ? AppColors.warningYellow.withOpacity(0.30)
            : AppColors.successGreen.withOpacity(0.30);
    final text = isHigh
        ? AppColors.dangerRed
        : s.riskLevel == 'MODERATE'
            ? AppColors.warningYellow
            : AppColors.successGreen;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(s.notes, style: TextStyle(color: text, height: 1.45)),
    );
  }

  Widget _ambiguity(WhisperfireAmbiguity a) {
    if (a.warning == null && (a.missingEvidence?.isEmpty ?? true)) {
      return Text('No ambiguity flagged.',
          style: TextStyle(color: AppColors.textGray500));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.warning != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              a.warning!,
              style: TextStyle(color: AppColors.warningYellow, height: 1.45),
            ),
          ),
        if (a.missingEvidence?.isNotEmpty ?? false) ...[
          Text('Missing Evidence:',
              style: TextStyle(
                color: AppColors.warningYellow, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _animatedBullets(a.missingEvidence!),
        ]
      ],
    );
  }

  Widget _premSection(String title, Widget child, {bool collapsible = false}) {
    return _sectionCard(
      title: title,
      child: child,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray600, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: AppColors.textGray300, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _timeNowLabel() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _GlowBox extends StatelessWidget {
  final Widget child;
  const _GlowBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.blueCyanGradient,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25)),
      ),
      child: child,
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MetricBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$value%', style: TextStyle(color: AppColors.textGray200, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, v, _) => Stack(
              children: [
                Container(height: 8, color: Colors.white.withOpacity(0.08)),
                FractionallySizedBox(
                  widthFactor: (v / 100).clamp(0, 1),
                  child: Container(height: 8, color: color.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
