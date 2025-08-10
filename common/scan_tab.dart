import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../models/whisperfire_models.dart';
import '../common/premium_output_card.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final _messageCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _relationship = 'Partner';
  String _tone = 'clinical';
  String _contentType = 'dm';

  bool _loading = false;
  WhisperfireResponse? _analysis;
  String? _error;

  final _relationships = const [
    'Partner','Ex','Date','Friend','Coworker','Family','Roommate','Stranger'
  ];
  final _tones = const ['savage','soft','clinical'];
  final _contentTypes = const ['dm','bio','story','post'];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      _toast('Please paste a message to analyze.');
      return;
    }
    setState(() {
      _loading = true;
      _analysis = null;
      _error = null;
    });
    try {
      final res = await ApiService.analyzeMessageWhisperfire(
        inputText: msg,
        contentType: _contentType,
        analysisGoal: 'scan',
        tone: _tone,
        relationship: _relationship,
        subjectName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      setState(() => _analysis = res);
    } catch (e) {
      setState(() => _error = e.toString());
      _toast('Scan failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // header
          const SizedBox(height: 16),
          const Text(
            'Scan',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // selectors
          _selectorsRow(),

          const SizedBox(height: 12),
          _textField(
            controller: _nameCtrl,
            hint: 'Subject name (optional)',
          ),
          const SizedBox(height: 12),
          _textArea(
            controller: _messageCtrl,
            hint: 'Paste the message you want to analyze…',
          ),
          const SizedBox(height: 12),

          // button
          _primaryButton(
            label: _loading ? 'Analyzing…' : '🔍 Analyze Message',
            onTap: _loading ? null : _runScan,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorBox(_error!),
          ],

          const SizedBox(height: 20),

          // result
          if (_analysis?.data != null)
            PremiumOutputCard(
              analysis: _analysis!,
              tab: 'scan',
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _selectorsRow() {
    return Row(
      children: [
        Expanded(child: _dropdown(
          label: 'Relationship',
          value: _relationship,
          items: _relationships,
          onChanged: (v) => setState(() => _relationship = v!),
        )),
        const SizedBox(width: 8),
        Expanded(child: _dropdown(
          label: 'Tone',
          value: _tone,
          items: _tones,
          onChanged: (v) => setState(() => _tone = v!),
        )),
        const SizedBox(width: 8),
        Expanded(child: _dropdown(
          label: 'Content',
          value: _contentType,
          items: _contentTypes,
          onChanged: (v) => setState(() => _contentType = v!),
        )),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray800,
            borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
            border: Border.all(color: AppColors.borderGray600, width: 0.8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.backgroundGray800,
              iconEnabledColor: Colors.white,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGray800,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(color: AppColors.borderGray600, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textGray500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _textArea({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGray800,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: AppColors.borderGray600, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        minLines: 5,
        maxLines: 10,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textGray500),
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _primaryButton({required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.largeRadius)),
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withOpacity(0.1),
        border: Border.all(color: AppColors.dangerRed.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
      ),
      child: Text(msg, style: TextStyle(color: AppColors.dangerRed)),
    );
  }
}
