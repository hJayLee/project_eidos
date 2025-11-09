import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/app_constants.dart' as app_constants;
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart' as slide_models;
import '../../../../services/ai/slide_ai_service.dart';
import '../../../../services/avatar/avatar_audio_service.dart';

/// 에디터 우측 컨텍스트 패널
class EditorContextPanel extends StatefulWidget {
  const EditorContextPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.slide,
    required this.onSlideUpdated,
  });

  final LectureProject project;
  final int selectedSlideIndex;
  final slide_models.SlideData? slide;
  final ValueChanged<slide_models.SlideData> onSlideUpdated;

  @override
  State<EditorContextPanel> createState() => _EditorContextPanelState();
}

class _EditorContextPanelState extends State<EditorContextPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void didUpdateWidget(covariant EditorContextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSlideIndex != oldWidget.selectedSlideIndex) {
      // 기본적으로 콘텐츠 탭으로 돌아가도록 설정
      _tabController.index = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          left: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: '콘텐츠'),
              Tab(text: '디자인'),
              Tab(text: '스크립트'),
              Tab(text: '에셋'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContentPane(
                  slide: widget.slide,
                  onSlideUpdated: widget.onSlideUpdated,
                ),
                _DesignPane(slide: widget.slide),
                _ScriptPane(
                  project: widget.project,
                  slide: widget.slide,
                  onSlideUpdated: widget.onSlideUpdated,
                ),
                _AssetsPane(project: widget.project),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final slideCount = widget.project.slides.length;
    final slideLabel = slideCount == 0
        ? '슬라이드 없음'
        : '슬라이드 ${widget.selectedSlideIndex + 1} / $slideCount';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '컨텍스트 패널',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                slideLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          if (widget.slide != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.slide!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentPane extends StatefulWidget {
  const _ContentPane({
    required this.slide,
    required this.onSlideUpdated,
  });

  final slide_models.SlideData? slide;
  final ValueChanged<slide_models.SlideData> onSlideUpdated;

  @override
  State<_ContentPane> createState() => _ContentPaneState();
}

class _ContentPaneState extends State<_ContentPane> {
  late final TextEditingController _titleController;
  slide_models.SlideData? _draftSlide;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.slide?.title ?? '');
  }

  @override
  void didUpdateWidget(covariant _ContentPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingSlide = widget.slide;
    final previousSlide = oldWidget.slide;

    final slideIdChanged = incomingSlide?.id != previousSlide?.id;
    final slideUpdatedExternally =
        incomingSlide != null && _draftSlide != null && incomingSlide.updatedAt.isAfter(_draftSlide!.updatedAt);

    if (slideIdChanged || slideUpdatedExternally) {
      _draftSlide = null;
      _titleController
        ..text = incomingSlide?.title ?? ''
        ..selection = TextSelection.collapsed(offset: _titleController.text.length);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _draftSlide ?? widget.slide;

    if (slide == null) {
      return const _EmptyState(
        icon: Icons.article_outlined,
        title: '선택된 슬라이드가 없습니다',
        description: '좌측 목록에서 슬라이드를 선택하거나 새 슬라이드를 생성해주세요.',
      );
    }

    final currentSlide = slide;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('제목'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '슬라이드 제목을 입력하세요',
            ),
            onChanged: (value) {
              if (value == currentSlide.title) return;
              final updatedSlide = currentSlide.copyWith(title: value);
              setState(() {
                _draftSlide = updatedSlide;
              });
              widget.onSlideUpdated(updatedSlide);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _SectionTitle('핵심 포인트'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addBulletPoint(currentSlide),
                icon: const Icon(Icons.add),
                label: const Text('포인트 추가'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: slide.elements.isEmpty
                ? _PlaceholderCard(
                    icon: Icons.list_alt_outlined,
                    title: '핵심 포인트가 없습니다',
                    subtitle: 'AI에게 요청하거나 직접 포인트를 추가할 수 있습니다.',
                    actionLabel: '첫 포인트 추가',
                    onTap: () => _addBulletPoint(slide),
                  )
                : ReorderableListView.builder(
                    itemCount: currentSlide.elements.length,
                    onReorder: (oldIndex, newIndex) =>
                        _reorderPoint(currentSlide, oldIndex, newIndex),
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: 1.0 + (animation.value * 0.02),
                            child: Material(
                              color: Colors.transparent,
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                    itemBuilder: (context, index) {
                      final element = currentSlide.elements[index];
                      final importance =
                          element.data['importance']?.toString() ?? 'normal';
                      final textStyle = Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontWeight: importance == 'highlight'
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: importance == 'highlight'
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimaryColor,
                          );

                      return Card(
                        key: ValueKey(element.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 8, top: 6),
                                  child: Icon(Icons.drag_handle_rounded),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('point-${element.id}'),
                                  initialValue:
                                      element.data['text']?.toString() ?? '',
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: '핵심 포인트를 입력하세요',
                                    border: InputBorder.none,
                                  ),
                                  style: textStyle,
                                  onChanged: (value) {
                                    _updatePoint(
                                      currentSlide,
                                      element.copyWith(
                                        data: {
                                          ...element.data,
                                          'text': value,
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: importance == 'highlight'
                                    ? '강조 해제'
                                    : '중요 포인트로 강조',
                                onPressed: () => _togglePointImportance(
                                  currentSlide,
                                  element,
                                ),
                                icon: Icon(
                                  importance == 'highlight'
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: importance == 'highlight'
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                              IconButton(
                                tooltip: '포인트 삭제',
                                onPressed: () =>
                                    _removePoint(currentSlide, element),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addBulletPoint(slide_models.SlideData slide) {
    final newElement = slide_models.SlideElement.create(
      type: app_constants.SlideElementType.text,
      data: {
        'text': '새로운 핵심 포인트',
        'style': 'bullet',
        'importance': 'normal',
      },
    );
    final updatedSlide = slide.addElement(newElement);
    setState(() {
      _draftSlide = updatedSlide;
    });
    widget.onSlideUpdated(updatedSlide);
  }

  void _removePoint(slide_models.SlideData slide, slide_models.SlideElement element) {
    final updatedSlide = slide.removeElement(element.id);
    setState(() {
      _draftSlide = updatedSlide;
    });
    widget.onSlideUpdated(updatedSlide);
  }

  void _togglePointImportance(
    slide_models.SlideData slide,
    slide_models.SlideElement element,
  ) {
    final currentImportance =
        element.data['importance']?.toString() ?? 'normal';
    final nextImportance =
        currentImportance == 'highlight' ? 'normal' : 'highlight';

    final updatedElement = element.copyWith(
      data: {
        ...element.data,
        'importance': nextImportance,
      },
    );

    _updatePoint(slide, updatedElement);
  }

  void _updatePoint(
    slide_models.SlideData slide,
    slide_models.SlideElement updatedElement,
  ) {
    final updatedSlide =
        slide.updateElement(updatedElement.id, updatedElement);
    setState(() {
      _draftSlide = updatedSlide;
    });
    widget.onSlideUpdated(updatedSlide);
  }

  void _reorderPoint(slide_models.SlideData slide, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final updatedSlide = slide.reorderElements(oldIndex, newIndex);
    setState(() {
      _draftSlide = updatedSlide;
    });
    widget.onSlideUpdated(updatedSlide);
  }
}

class _DesignPane extends StatelessWidget {
  const _DesignPane({required this.slide});

  final slide_models.SlideData? slide;

  @override
  Widget build(BuildContext context) {
    if (slide == null) {
      return _EmptyState(
        icon: Icons.palette_outlined,
        title: '디자인을 적용할 슬라이드를 선택하세요',
        description: '색상, 배경, 레이아웃을 원하는 스타일로 바꿀 수 있습니다.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          _SectionTitle('레이아웃 추천'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final layout in ['기본', '2단', '이미지 강조', '데이터 강조'])
                _SelectableCard(
                  title: layout,
                  isSelected: layout == '기본',
                  onTap: () {
                    // TODO: 레이아웃 변경
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('컬러 & 타이포그래피'),
          Wrap(
            spacing: 12,
            children: [
              _ColorSwatch(color: Colors.deepPurple),
              _ColorSwatch(color: Colors.orange),
              _ColorSwatch(color: Colors.blueGrey),
              _ColorSwatch(color: Colors.teal),
            ],
          ),
          const SizedBox(height: 24),
          _PlaceholderCard(
            icon: Icons.image_outlined,
            title: 'AI 이미지/아이콘 추천',
            subtitle: '슬라이드 주제에 어울리는 시각 요소를 AI가 찾아드립니다.',
            actionLabel: '추천 받기',
            onTap: () {
              // TODO: 이미지/아이콘 추천
            },
          ),
        ],
      ),
    );
  }
}

class _ScriptPane extends StatefulWidget {
  const _ScriptPane({
    required this.project,
    required this.slide,
    required this.onSlideUpdated,
  });

  final LectureProject project;
  final slide_models.SlideData? slide;
  final ValueChanged<slide_models.SlideData> onSlideUpdated;

  @override
  State<_ScriptPane> createState() => _ScriptPaneState();
}

class _ScriptPaneState extends State<_ScriptPane> {
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
  void didUpdateWidget(covariant _ScriptPane oldWidget) {
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
      return const _EmptyState(
        icon: Icons.record_voice_over_outlined,
        title: '스크립트를 편집할 슬라이드를 선택하세요',
        description: '슬라이드 내용을 설명할 강의 대본을 작성하고 다듬을 수 있습니다.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('강의 대본'),
          const SizedBox(height: 8),
          Wrap(
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
                onPressed: () {
                  // TODO: 다른 말투로 재작성
                },
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
                label: Text(
                  _isPreviewingAudio ? '미리듣기 준비 중...' : '아바타 음성 미리듣기',
                ),
              ),
            ],
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
                  Icon(Icons.error_outline,
                      color: AppTheme.error, size: 18),
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
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.error,
                    tooltip: '오류 숨기기',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: TextFormField(
              controller: _scriptController,
              expands: true,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '슬라이드 내용을 설명할 대본을 입력하세요.',
              ),
              onChanged: _applyScriptUpdate,
            ),
          ),
        ],
      ),
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
      _applyScriptUpdate(script);
      _showSnackBar(
        '대본 생성 완료',
        '${slide.title.isEmpty ? '슬라이드 대본' : '\'${slide.title}\''}이(가) 업데이트되었습니다.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar(
        '대본 생성 실패',
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _applyScriptUpdate(String value) {
    final slide = widget.slide;
    if (slide == null) return;

    _lastSyncedScript = value;

    final updatedMetadata = Map<String, dynamic>.from(slide.metadata);
    updatedMetadata['script'] = value;

    widget.onSlideUpdated(
      slide.copyWith(
        metadata: updatedMetadata,
        speakerNotes: value,
      ),
    );
    _showSnackBar(
      '대본이 업데이트되었습니다',
      slide.title.isEmpty
          ? '슬라이드 스크립트가 저장되었습니다.'
          : '\'${slide.title}\' 슬라이드 스크립트가 저장되었습니다.',
    );
  }

  Future<void> _previewAvatarAudio() async {
    final slide = widget.slide;
    if (slide == null) return;

    final script = _scriptController.text.trim();
    if (script.isEmpty) {
      _showSnackBar(
        '대본이 필요합니다',
        '대본을 작성하거나 AI로 생성한 후 미리듣기를 시도해주세요.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isPreviewingAudio = true;
      _errorMessage = null;
    });

    try {
      final preview = await AvatarAudioService.generatePreview(
        project: widget.project,
        slide: slide,
        script: script,
      );

      if (!mounted) return;
      _showSnackBar(
        '미리듣기 준비 완료',
        '예상 재생 시간: ${preview.estimatedDuration.inSeconds}초\n(데모 URL: ${preview.previewUrl})',
      );
      await _showAudioPreview(preview);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '미리듣기 실패',
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewingAudio = false;
        });
      }
    }
  }

  void _showSnackBar(
    String title,
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppTheme.error : AppTheme.primaryColor,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showAudioPreview(
    AvatarAudioPreviewResult preview,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Row(
            children: [
              Icon(Icons.play_circle_fill, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                '아바타 음성 미리듣기',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '데모용 URL이 준비되었습니다. 실제 음성 합성 API와 연결되면 자동 재생이 지원될 예정입니다.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.timer_outlined,
                  label: '예상 재생 시간',
                  value:
                      '${preview.estimatedDuration.inSeconds}초 (대본 길이에 따라 변동)',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.link,
                  label: '미리듣기 URL',
                  value: preview.previewUrl,
                  isLink: true,
                  onCopy: (dialogContext) async {
                    final messenger = ScaffoldMessenger.of(dialogContext);
                    await Clipboard.setData(
                      ClipboardData(text: preview.previewUrl),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('미리듣기 URL이 클립보드에 복사되었습니다.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '실제 음성 합성 엔드포인트 연동 시 이 프리뷰 창에서 바로 재생할 수 있도록 확장될 예정입니다.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final Future<void> Function(BuildContext context)? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isLink && onCopy != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => onCopy?.call(context),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('복사'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _AssetsPane extends StatelessWidget {
  const _AssetsPane({required this.project});

  final LectureProject project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('AI 아바타 & 음성'),
          const SizedBox(height: 12),
          _PlaceholderCard(
            icon: Icons.person_pin,
            title: 'AI 아바타 설정',
            subtitle: '내 사진을 업로드하거나 기존 아바타를 선택하세요.',
            actionLabel: '아바타 관리',
            onTap: () {
              // TODO: 아바타 관리 기능 연결
            },
          ),
          const SizedBox(height: 24),
          _SectionTitle('이미지 / 영상 에셋'),
          const SizedBox(height: 12),
          Expanded(
            child: _PlaceholderCard(
              icon: Icons.photo_library_outlined,
              title: '에셋 라이브러리',
              subtitle: '업로드한 이미지, AI가 생성한 시각 자료를 관리합니다.',
              actionLabel: '에셋 업로드',
              onTap: () {
                // TODO: 에셋 업로드
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppTheme.textSecondaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.title,
    required this.isSelected,
    this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderColor),
      ),
    );
  }
}

