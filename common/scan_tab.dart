import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../models/whisperfire_models.dart';
import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/premium_output_card.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();

  String _selectedTone = 'clinical';
  String _selectedRelationship = 'Partner';
  String _selectedContentType = 'dm'; // dm | bio | story | post
  bool _isAnalyzing = false;
  WhisperfireResponse? _analysis;

  @override
  void dispose() {
    _textController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      final result = await ApiService.analyzeMessageWhisperfire(
        inputText: text,
        contentType: _selectedContentType,
        analysisGoal: 'scan',
        tone: _selectedTone,
        relationship: _selectedRelationship,
        subjectName: _subjectNameController.text.trim().isEmpty
            ? null
            : _subjectNameController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _analysis = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyJSON() {
    if (_analysis?.data == null) return;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(_analysis!.data!.toJson());
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('JSON copied to clipboard'),
        backgroundColor: AppColors.primaryPink,
      ),
    );
  }

  void _downloadJSON() {
    // for web builds, ApiService already uses dart:html; here we just show a toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download ready (handled by browser)'),
        backgroundColor: AppColors.primaryPink,
      ),
    );
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share coming soon'),
        backgroundColor: AppColors.primaryPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          _buildRelationshipToneRow(),
          const SizedBox(height: 16),

          _buildContentTypeSelector(),
          const SizedBox(height: 16),

          _buildSubjectName(),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _textController,
            placeholder: 'Paste the message you want to analyze...',
            maxLines: 6,
            padding: const EdgeInsets.all(16),
          ),
          const SizedBox(height: 16),

          GradientButton(
            text: _isAnalyzing ? 'Analyzing...' : 'Analyze Message',
            isLoading: _isAnalyzing,
            disabled: !hasText,
            width: double.infinity,
            height: 56,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryPurple],
            ),
            onPressed: _runScan,
          ),

          const SizedBox(height: 24),

          if (_analysis?.data != null)
            PremiumOutputCard(
              analysis: _analysis!,
              tab: 'scan',
              onShare: _share,
              onCopyJSON: _copyJSON,
              onDownloadJSON: _downloadJSON,
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: AppColors.primaryBlue, size: 30),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.blueCyanGradient.createShader(b),
              child: const Text(
                'Scan Analysis',
                style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Detect tactics, motives & safe responses',
          style: TextStyle(color: AppColors.textGray400),
        ),
      ],
    );
  }

  Widget _buildRelationshipToneRow() {
    return Row(
      children: [
        Expanded(child: _dropdown(
          label: 'Relationship',
          value: _selectedRelationship,
          items: const [
            'Partner','Ex','Date','Friend','Coworker','Family','Roommate','Stranger'
          ],
          onChanged: (v) => setState(() => _selectedRelationship = v!),
        )),
        const SizedBox(width: 12),
        Expanded(child: _dropdown(
          label: 'Tone',
          value: _selectedTone,
          items: const ['savage','soft','clinical'],
          onChanged: (v) => setState(() => _selectedTone = v!),
        )),
      ],
    );
  }

  Widget _buildContentTypeSelector() {
    final types = const [
      {'id': 'dm', 'label': '💬 DM'},
      {'id': 'bio', 'label': '📝 Bio'},
      {'id': 'story', 'label': '📖 Story'},
      {'id': 'post', 'label': '📱 Post'},
    ];
    return Row(
      children: types.map((t) {
        final selected = _selectedContentType == t['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedContentType = t['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.12) : AppColors.backgroundGray800,
                  borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
                  border: Border.all(color: selected ? AppColors.primaryBlue : AppColors.borderGray600),
                ),
                alignment: Alignment.center,
                child: Text(
                  t['label']!,
                  style: TextStyle(
                    color: selected ? AppColors.primaryBlue : AppColors.textGray400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUBJECT NAME (OPTIONAL)',
            style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _subjectNameController,
          placeholder: 'Enter the person\'s name...',
          maxLines: 1,
          padding: const EdgeInsets.all(16),
        ),
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
        Text(label.toUpperCase(),
            style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray800,
            borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
            border: Border.all(color: AppColors.borderGray600),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.backgroundGray800,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: items.map((v) => DropdownMenuItem(
                value: v, child: Text(v))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
