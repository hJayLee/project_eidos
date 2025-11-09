import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/script.dart';
import '../../../../data/models/slide.dart';
import '../../../../services/ai/slide_ai_service.dart';

/// 슬라이드 생성 패널
class SlideGenerationPanel extends StatefulWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final Future<void> Function(List<SlideData> slides) onSlidesGenerated;

  const SlideGenerationPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlidesGenerated,
  });

  @override
  State<SlideGenerationPanel> createState() => _SlideGenerationPanelState();
}

class _SlideGenerationPanelState extends State<SlideGenerationPanel> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;
  int _slideCount = 5;

  @override
  void dispose() {
    _promptController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _generateSlides() async {
    if (_isGenerating) return;

    final prompt = _promptController.text.trim();
    final keywordsInput = _keywordsController.text.trim();
    final existingScript = widget.project.script.content.trim();

    final buffer = StringBuffer();
    if (prompt.isNotEmpty) {
      buffer.writeln(prompt);
    }
    if (keywordsInput.isNotEmpty) {
      buffer.writeln('\n키워드: $keywordsInput');
    }
    if (existingScript.isNotEmpty) {
      buffer.writeln('\n$existingScript');
    }

    final scriptContent = buffer.toString().trim();
    if (scriptContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('슬라이드 생성을 위해 프롬프트 또는 스크립트 내용이 필요합니다'),
        ),
      );
      return;
    }

    final script = Script.create(content: scriptContent);
    final keywords = keywordsInput
        .split(',')
        .map((keyword) => keyword.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList();

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final slides = await SlideAIService.generateSlidesFromScript(
        script: script,
        category: widget.project.settings.templateCategory,
        maxSlides: _slideCount,
      );

      final nowIso = DateTime.now().toIso8601String();
      final processedSlides = <SlideData>[
        for (var i = 0; i < slides.length; i++)
          slides[i].copyWith(
            title: slides[i].title.isEmpty
                ? 'AI 슬라이드 ${i + 1}'
                : slides[i].title,
            metadata: {
              ...slides[i].metadata,
              'generatedAt': nowIso,
              'generatedBy': 'SlideAIService',
              if (prompt.isNotEmpty) 'sourcePrompt': prompt,
              if (keywords.isNotEmpty) 'keywords': keywords,
            },
          ),
      ];

      if (!mounted) return;
      await widget.onSlidesGenerated(processedSlides);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI 슬라이드 ${processedSlides.length}개가 생성되었습니다',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        setState(() {
          _errorMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('슬라이드 생성에 실패했습니다: $message'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.slideshow,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '슬라이드 생성',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 프롬프트 입력
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 프롬프트 입력창
                  TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      labelText: '프롬프트',
                      hintText: '슬라이드 내용을 상세히 입력하세요...',
                      hintStyle: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  const SizedBox(height: 16),
                  // 키워드 입력창
                  TextField(
                    controller: _keywordsController,
                    decoration: InputDecoration(
                      labelText: '키워드',
                      hintText: 'AI, 미래, 기술, 혁신 (쉼표로 구분)',
                      hintStyle: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '생성할 슬라이드 수',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<int>(
                              value: _slideCount,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              icon: const Icon(Icons.expand_more),
                              items: const [1, 3, 5, 8]
                                  .map(
                                    (count) => DropdownMenuItem<int>(
                                      value: count,
                                      child: Text('$count 장 생성'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isGenerating
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _slideCount = value;
                                      });
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 생성 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateSlides,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isGenerating ? '생성 중...' : '슬라이드 생성'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 생성 상태
                  if (_isGenerating)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI가 슬라이드를 생성하고 있습니다...',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.error,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
