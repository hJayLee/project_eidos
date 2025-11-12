import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart' show SlideElementType;
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart';
import 'editable_slide_canvas.dart';
import 'script_editor_panel.dart';

/// 슬라이드 미리보기 패널
class SlidePreviewPanel extends StatefulWidget {
  const SlidePreviewPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlideUpdated,
  });

  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<SlideData> onSlideUpdated;

  @override
  State<SlidePreviewPanel> createState() => _SlidePreviewPanelState();
}

class _SlidePreviewPanelState extends State<SlidePreviewPanel> {
  final GlobalKey<EditableSlideCanvasState> _canvasKey =
      GlobalKey<EditableSlideCanvasState>();
  ValueListenable<SlideElement?>? _selectionListenable;
  EditableSlideCanvasState? _lastCanvasState;
  final ValueNotifier<SlideElement?> _emptySelection =
      ValueNotifier<SlideElement?>(null);

  @override
  void initState() {
    super.initState();
    _scheduleSyncSelection();
  }

  void _scheduleSyncSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectionListenable();
    });
  }

  void _syncSelectionListenable() {
    final canvasState = _canvasKey.currentState;
    if (_lastCanvasState == canvasState && _selectionListenable != null) {
      return;
    }

    final newListenable = canvasState?.selectionNotifier ?? _emptySelection;
    if (identical(newListenable, _selectionListenable)) {
      return;
    }

    setState(() {
      _selectionListenable = newListenable;
      _lastCanvasState = canvasState;
    });
  }

  @override
  void didUpdateWidget(covariant SlidePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSlideIndex != oldWidget.selectedSlideIndex ||
        widget.project.slides.length != oldWidget.project.slides.length) {
      _scheduleSyncSelection();
    }
  }

  @override
  void dispose() {
    _emptySelection.dispose();
    super.dispose();
  }

  EditableSlideCanvasState? get _canvasState => _canvasKey.currentState;

  void _handleAddText() {
    _canvasState?.addTextElement();
  }

  void _handleAddImage() {
    _canvasState?.addImageElement();
  }

  void _handleDeleteSelection() {
    _canvasState?.deleteSelectedElement();
  }

  void _handleFontNudge(double delta) {
    _canvasState?.nudgeSelectedTextFontSize(delta);
  }

  void _handleFontSelect(double size) {
    _canvasState?.setSelectedTextFontSize(size);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncSelectionListenable();
      }
    });

    final slide = widget.selectedSlideIndex < widget.project.slides.length
        ? widget.project.slides[widget.selectedSlideIndex]
        : null;

    final hasSlide = slide != null;
    final listenable = _selectionListenable ?? _emptySelection;

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: ValueListenableBuilder<SlideElement?>(
        valueListenable: listenable,
        builder: (context, selected, _) {
          final hasSelection = selected != null;
          final isTextSelected =
              selected?.type == SlideElementType.text ?? false;
          final fontSize = _canvasKey.currentState?.selectedTextFontSize;

          return Column(
            children: [
              _SlideEditorToolbar(
                hasSlide: hasSlide,
                hasSelection: hasSelection,
                canAdjustFont: isTextSelected,
                fontSize: isTextSelected ? fontSize : null,
                onAddText: hasSlide ? _handleAddText : null,
                onAddImage: hasSlide ? _handleAddImage : null,
                onDeleteSelection: hasSelection ? _handleDeleteSelection : null,
                onFontSizeDecrease: isTextSelected
                    ? () => _handleFontNudge(-2)
                    : null,
                onFontSizeIncrease: isTextSelected
                    ? () => _handleFontNudge(2)
                    : null,
                onFontSizeSelected: isTextSelected ? _handleFontSelect : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 28,
                            offset: Offset(0, 18),
                            spreadRadius: -12,
                          ),
                        ],
                      ),
                      child: slide == null
                          ? const _EmptySlidePlaceholder()
                          : _SlideStage(
                              slide: slide,
                              onSlideUpdated: widget.onSlideUpdated,
                              canvasKey: _canvasKey,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                fit: FlexFit.loose,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ScriptEditorPanel(
                    project: widget.project,
                    slide: slide,
                    onSlideUpdated: widget.onSlideUpdated,
                    embedded: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlideStage extends StatelessWidget {
  const _SlideStage({
    required this.slide,
    required this.onSlideUpdated,
    required this.canvasKey,
  });

  final SlideData slide;
  final ValueChanged<SlideData> onSlideUpdated;
  final GlobalKey<EditableSlideCanvasState> canvasKey;

  static const double _designWidth = 1280;
  static const double _designHeight = 720;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _designWidth,
          height: _designHeight,
          child: EditableSlideCanvas(
            key: canvasKey,
            slide: slide,
            onSlideUpdated: onSlideUpdated,
          ),
        ),
      ),
    );
  }
}

class _EmptySlidePlaceholder extends StatelessWidget {
  const _EmptySlidePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.slideshow_outlined,
                size: 64,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                '아직 생성된 슬라이드가 없어요',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '새 프로젝트를 생성하거나 직접 첫 번째 슬라이드를 만들어보세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideEditorToolbar extends StatelessWidget {
  const _SlideEditorToolbar({
    required this.hasSlide,
    required this.hasSelection,
    required this.canAdjustFont,
    required this.fontSize,
    this.onAddText,
    this.onAddImage,
    this.onDeleteSelection,
    this.onFontSizeDecrease,
    this.onFontSizeIncrease,
    this.onFontSizeSelected,
  });

  final bool hasSlide;
  final bool hasSelection;
  final bool canAdjustFont;
  final double? fontSize;
  final VoidCallback? onAddText;
  final VoidCallback? onAddImage;
  final VoidCallback? onDeleteSelection;
  final VoidCallback? onFontSizeDecrease;
  final VoidCallback? onFontSizeIncrease;
  final ValueChanged<double>? onFontSizeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          const _ToolbarTag(label: 'Body Text'),
          const _ToolbarTag(label: 'Default'),
          _FontSizeControl(
            enabled: canAdjustFont,
            fontSize: fontSize,
            onDecrease: onFontSizeDecrease,
            onIncrease: onFontSizeIncrease,
            onSelect: onFontSizeSelected,
          ),
          const _ToolbarDivider(),
          const _ToolbarIconButton(icon: Icons.format_bold, tooltip: '굵게'),
          const _ToolbarIconButton(icon: Icons.format_italic, tooltip: '기울임꼴'),
          const _ToolbarIconButton(
            icon: Icons.format_underlined,
            tooltip: '밑줄',
          ),
          const _ToolbarIconButton(
            icon: Icons.format_strikethrough,
            tooltip: '취소선',
          ),
          const _ToolbarDivider(),
          const _ToolbarIconButton(
            icon: Icons.format_align_left,
            tooltip: '왼쪽 정렬',
          ),
          const _ToolbarIconButton(
            icon: Icons.format_align_center,
            tooltip: '가운데 정렬',
          ),
          const _ToolbarIconButton(
            icon: Icons.format_align_right,
            tooltip: '오른쪽 정렬',
          ),
          const _ToolbarIconButton(
            icon: Icons.format_align_justify,
            tooltip: '양쪽 정렬',
          ),
          const _ToolbarDivider(),
          const _ToolbarIconButton(
            icon: Icons.palette_outlined,
            tooltip: '텍스트 색상',
          ),
          const _ToolbarIconButton(
            icon: Icons.highlight_outlined,
            tooltip: '하이라이트',
          ),
          const _ToolbarDivider(),
          OutlinedButton.icon(
            onPressed: onDeleteSelection,
            icon: const Icon(Icons.delete_outline),
            label: const Text('삭제'),
            style: OutlinedButton.styleFrom(
              foregroundColor: onDeleteSelection != null
                  ? Colors.redAccent
                  : null,
            ),
          ),
          FilledButton.icon(
            onPressed: onAddText,
            icon: const Icon(Icons.text_fields),
            label: const Text('텍스트 추가'),
          ),
          FilledButton.icon(
            onPressed: onAddImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('이미지 추가'),
          ),
        ],
      ),
    );
  }
}

class _ToolbarTag extends StatelessWidget {
  const _ToolbarTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: VerticalDivider(
        color: AppTheme.borderColor.withOpacity(0.4),
        thickness: 1,
        width: 1,
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  const _FontSizeControl({
    required this.enabled,
    required this.fontSize,
    this.onDecrease,
    this.onIncrease,
    this.onSelect,
  });

  final bool enabled;
  final double? fontSize;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final ValueChanged<double>? onSelect;

  static const List<double> _presetSizes = [
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    40,
    48,
  ];

  @override
  Widget build(BuildContext context) {
    final options = <double>{..._presetSizes};
    if (fontSize != null) {
      options.add(fontSize!.clamp(8, 120));
    }
    final sortedOptions = options.toList()..sort();
    final label = fontSize != null ? fontSize!.toStringAsFixed(0) : '--';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            tooltip: '폰트 크기 감소',
            onPressed: enabled ? onDecrease : null,
          ),
          PopupMenuButton<double>(
            enabled: enabled && onSelect != null,
            tooltip: '폰트 크기 선택',
            initialValue: fontSize,
            onSelected: (value) => onSelect?.call(value),
            itemBuilder: (context) => [
              for (final size in sortedOptions)
                PopupMenuItem<double>(
                  value: size,
                  child: Text('${size.toStringAsFixed(0)} pt'),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$label pt',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: '폰트 크기 증가',
            onPressed: enabled ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}
