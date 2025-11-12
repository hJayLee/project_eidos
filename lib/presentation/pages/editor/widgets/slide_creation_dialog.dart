import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';

class SlideCreationResult {
  const SlideCreationResult({
    required this.title,
    required this.prompt,
    required this.createEmpty,
  });

  final String title;
  final String prompt;
  final bool createEmpty;
}

class SlideCreationDialog extends StatefulWidget {
  const SlideCreationDialog({super.key});

  static Future<SlideCreationResult?> show(BuildContext context) {
    return showDialog<SlideCreationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SlideCreationDialog(),
    );
  }

  @override
  State<SlideCreationDialog> createState() => _SlideCreationDialogState();
}

class _SlideCreationDialogState extends State<SlideCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  String? _blankErrorText;

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _handleGenerate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      SlideCreationResult(
        title: _titleController.text.trim(),
        prompt: _promptController.text.trim(),
        createEmpty: false,
      ),
    );
  }

  void _handleCreateEmpty() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _blankErrorText = '슬라이드 제목을 입력해 주세요.';
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(SlideCreationResult(title: title, prompt: '', createEmpty: true));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '슬라이드 추가',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '슬라이드 제목과 프롬프트를 입력하면 AI가 한 장의 슬라이드를 생성합니다.\n빈 슬라이드를 추가할 수도 있습니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '슬라이드 제목',
                          hintText: '예: 생성형 AI의 핵심 개념',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '슬라이드 제목을 입력해 주세요.';
                          }
                          if (value.trim().length < 2) {
                            return '2자 이상 입력해 주세요.';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          if (_blankErrorText != null) {
                            setState(() => _blankErrorText = null);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          labelText: '프롬프트',
                          hintText: '이 슬라이드에서 전달하고 싶은 내용을 자세히 작성해주세요.',
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'AI 생성을 위해 프롬프트를 입력해 주세요.';
                          }
                          if (value.trim().length < 10) {
                            return '조금 더 구체적으로 작성해 주세요 (10자 이상).';
                          }
                          return null;
                        },
                      ),
                      if (_blankErrorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _blankErrorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _handleCreateEmpty,
                      child: const Text('빈 슬라이드 생성'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleGenerate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('AI로 생성'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
