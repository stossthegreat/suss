import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../models/whisperfire_models.dart';

import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/outlined_button.dart';


class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();

  String _selectedRelationship = 'Partner';
  String _selectedTone = 'clinical';
  String _selectedContentType = 'dm';

  bool _isAnalyzing = false;
  WhisperfireResponse? _analysis;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    final text = _messageController.text.trim();
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
        SnackBar(content: Text('Scan failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _messageController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // message input
          CustomTextField(
            controller: _messageController,
            placeholder: 'Paste the message you want to analyze...',
            maxLines: 6,
            padding: const EdgeInsets.all(16),
          ),
          const SizedBox(height: 20),

          // subject name (optional)
          _buildSubjectNameField(),
          const SizedBox(height: 20),

          // relationship
          _buildRelationshipSelector(),
          const SizedBox(height: 20),

          // tone
          _buildToneSelector(),
          const SizedBox(height: 20),

          // content type
          _buildContentTypeSelector(),
          const SizedBox(height: 24),

          // analyze
          GradientButton(
            text: _isAnalyzing ? 'Analyzing...' : 'Analyze Message',
            isLoading: _isAnalyzing,
            disabled: !hasText,
            icon: _isAnalyzing ? null : const Icon(Icons.search, color: Colors.white),
            width: double.infinity,
            height: 56,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryPurple],
            ),
            onPressed: _runScan,
          ),
          const SizedBox(height: 24),

          // results (premium)
          if (_analysis?.data != null)
            PremiumOutputCard(
              tab: 'scan',
              data: _analysis!.data!,
              onShare: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share coming soon!')),
                );
              },
              onCopyJSON: () {
                final jsonStr = jsonEncode(_analysis!.toJson());
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON copied')),
                );
              },
              onDownloadJSON: () {
                final jsonStr = jsonEncode(_analysis!.toJson());
                Clipboard.setData(ClipboardData(text: jsonStr)); // simple fallback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloaded (copied for now)')),
                );
              },
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: AppColors.primaryBlue, size: 32),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryPurple]).createShader(bounds),
              child: const Text(
                'Scan Analysis',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Detect manipulation signals in one message',
          style: TextStyle(color: AppColors.textGray400, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSubjectNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUBJECT NAME (OPTIONAL)',
            style: TextStyle(
              color: AppColors.textGray400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _subjectNameController,
          placeholder: 'Enter the person\'s name...',
          maxLines: 1,
          padding: const EdgeInsets.all(16),
        ),
      ],
    );
  }

  Widget _buildRelationshipSelector() {
    final relationships = [
      {'id': 'Partner', 'label': '💕 Partner', 'desc': 'Romantic relationships'},
      {'id': 'Ex', 'label': '💔 Ex', 'desc': 'Former partners'},
      {'id': 'Date', 'label': '💘 Date', 'desc': 'Dating situations'},
      {'id': 'Friend', 'label': '👥 Friend', 'desc': 'Friendships'},
      {'id': 'Coworker', 'label': '💼 Coworker', 'desc': 'Work relationships'},
      {'id': 'Family', 'label': '👨‍👩‍👧‍👦 Family', 'desc': 'Family dynamics'},
      {'id': 'Roommate', 'label': '🏡 Roommate', 'desc': 'Living situations'},
      {'id': 'Stranger', 'label': '❓ Stranger', 'desc': 'Unknown people'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RELATIONSHIP CONTEXT',
            style: TextStyle(
              color: AppColors.textGray400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray800,
            borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
            border: Border.all(color: AppColors.borderGray600),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRelationship,
              isExpanded: true,
              dropdownColor: AppColors.backgroundGray800,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: relationships
                  .map((rel) => DropdownMenuItem<String>(
                        value: rel['id']!,
                        child: Row(
                          children: [
                            Text(rel['label']!),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(rel['desc']!,
                                  style: TextStyle(color: AppColors.textGray400, fontSize: 12)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRelationship = v ?? _selectedRelationship),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToneSelector() {
    final tones = [
      {'id': 'savage', 'label': '🔥 Savage', 'desc': 'No mercy'},
      {'id': 'soft', 'label': '🕊️ Soft', 'desc': 'Gentle approach'},
      {'id': 'clinical', 'label': '🧠 Clinical', 'desc': 'Analytical & precise'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ANALYSIS TONE',
            style: TextStyle(
              color: AppColors.textGray400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 12),
        Row(
          children: tones
              .map(
                (tone) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CustomOutlinedButton(
                      text: '',
                      isSelected: _selectedTone == tone['id'],
                      selectedColor: AppColors.primaryPink,
                      onPressed: () => setState(() => _selectedTone = tone['id']!),
                      child: Column(
                        children: [
                          Text(
                            tone['label']!,
                            style: TextStyle(
                              color: _selectedTone == tone['id']
                                  ? AppColors.primaryPink
                                  : AppColors.textGray400,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tone['desc']!,
                            style: TextStyle(
                              color: (_selectedTone == tone['id']
                                      ? AppColors.primaryPink
                                      : AppColors.textGray400)
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildContentTypeSelector() {
    final contentTypes = [
      {'id': 'dm', 'label': 'Direct Message', 'desc': 'One-to-one chats'},
      {'id': 'bio', 'label': 'Bio', 'desc': 'Social bio'},
      {'id': 'story', 'label': 'Story', 'desc': 'Stories'},
      {'id': 'post', 'label': 'Post', 'desc': 'Public post'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTENT TYPE',
            style: TextStyle(
              color: AppColors.textGray400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 12),
        Row(
          children: contentTypes
              .map(
                (type) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CustomOutlinedButton(
                      text: '',
                      isSelected: _selectedContentType == type['id'],
                      selectedColor: AppColors.primaryBlue,
                      onPressed: () => setState(() => _selectedContentType = type['id']!),
                      child: Column(
                        children: [
                          Text(
                            type['label']!,
                            style: TextStyle(
                              color: _selectedContentType == type['id']
                                  ? AppColors.primaryBlue
                                  : AppColors.textGray400,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type['desc']!,
                            style: TextStyle(
                              color: (_selectedContentType == type['id']
                                      ? AppColors.primaryBlue
                                      : AppColors.textGray400)
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
