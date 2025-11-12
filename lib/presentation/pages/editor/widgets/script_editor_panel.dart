import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart' as slide_models;
import '../../../../services/ai/slide_ai_service.dart';
import '../../../../services/avatar/avatar_audio_service.dart';

class ScriptEditorPanel extends StatefulWidget {
  const ScriptEditorPanel({
    super.key,
    required this.project,
    required this.slide,
    required this.onSlideUpdated,
    this.embedded = false,
  });

  final LectureProject project;
  final slide_models.SlideData? slide;
  final ValueChanged<slide_models.SlideData> onSlideUpdated;
  final bool embedded;

  @override
  State<ScriptEditorPanel> createState() => _ScriptEditorPanelState();
}

class _ScriptEditorPanelState extends State<ScriptEditorPanel> {
  late final TextEditingController _scriptController;
  String? _lastSyncedScript;
  bool _isGenerating = false;
  bool _isPreviewingAudio = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialScript = _extractScript(widget.slide);
    _scriptController = TextEditingController(text: initialScript);
    _lastSyncedScript = initialScript;
  }

  @override
  void didUpdateWidget(covariant ScriptEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newSlide = widget.slide;
    final oldSlide = oldWidget.slide;
    final newScript = _extractScript(newSlide);

    final slideChanged = newSlide?.id != oldSlide?.id;
    final externalUpdate =
        newScript != _lastSyncedScript && newScript != _scriptController.text;

    if (slideChanged || externalUpdate) {
      _scriptController
        ..text = newScript
        ..selection = TextSelection.collapsed(offset: newScript.length);
      _lastSyncedScript = newScript;
    }
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    if (slide == null) {
      return const _EmptyScriptState();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _ErrorBanner(
            message: _errorMessage!,
            onDismiss: () => setState(() => _errorMessage = null),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: TextFormField(
            controller: _scriptController,
            expands: true,
            maxLines: null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: '슬라이드 내용을 설명할 대본을 입력하세요.',
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: AppTheme.surfaceColor.withValues(alpha: 0.6),
            ),
            onChanged: _applyScriptUpdate,
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.6)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: content,
      );
    }

    return Padding(padding: const EdgeInsets.all(20), child: content);
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateScriptWithAI,
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(_isGenerating ? '생성 중...' : 'AI로 대본 생성'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        TextButton.icon(
          onPressed: _isGenerating ? null : _rewriteScript,
          icon: const Icon(Icons.auto_fix_high_outlined),
          label: const Text('다른 말투로 재작성'),
        ),
        OutlinedButton.icon(
          onPressed: _isPreviewingAudio ? null : _previewAvatarAudio,
          icon: _isPreviewingAudio
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_isPreviewingAudio ? '미리듣기 준비 중...' : '아바타 음성 미리듣기'),
        ),
      ],
    );
  }

  String _extractScript(slide_models.SlideData? slide) {
    if (slide == null) return '';
    final metadataScript = slide.metadata['script']?.toString() ?? '';
    if (metadataScript.trim().isNotEmpty) {
      return metadataScript;
    }
    return slide.speakerNotes ?? '';
  }

  Future<void> _generateScriptWithAI() async {
    final slide = widget.slide;
    if (slide == null) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final script = await SlideAIService.generateScriptForSlide(
        slide: slide,
        category: widget.project.settings.templateCategory,
        projectDescription: widget.project.description,
        voiceTone: widget.project.metadata['voiceTone']?.toString(),
      );

      if (!mounted) return;

      _scriptController
        ..text = script
        ..selection = TextSelection.collapsed(offset: script.length);
      _lastSyncedScript = script;
      _applyScriptUpdate(script);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _rewriteScript() async {
    // TODO: 다른 말투로 재작성 기능
  }

  Future<void> _previewAvatarAudio() async {
    final slide = widget.slide;
    if (slide == null) return;
    final script = _scriptController.text.trim();
    if (script.isEmpty) return;

    setState(() {
      _isPreviewingAudio = true;
    });

    try {
      await AvatarAudioService.generatePreview(
        project: widget.project,
        slide: slide,
        script: script,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isPreviewingAudio = false;
      });
    }
  }

  void _applyScriptUpdate(String value) {
    final slide = widget.slide;
    if (slide == null) return;

    final updatedSlide = slide.copyWith(
      speakerNotes: value,
      metadata: {...slide.metadata, 'script': value},
    );

    _lastSyncedScript = value;
    widget.onSlideUpdated(updatedSlide);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.error,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
            color: AppTheme.error,
            tooltip: '오류 숨기기',
          ),
        ],
      ),
    );
  }
}

class _EmptyScriptState extends StatelessWidget {
  const _EmptyScriptState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '스크립트를 편집할 슬라이드를 선택하세요',
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
      ),
    );
  }
}
