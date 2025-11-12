import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart' show SlideElementType;
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/slide.dart';

class EditableSlideCanvas extends StatefulWidget {
  const EditableSlideCanvas({
    super.key,
    required this.slide,
    required this.onSlideUpdated,
  });

  final SlideData slide;
  final ValueChanged<SlideData> onSlideUpdated;

  @override
  EditableSlideCanvasState createState() => EditableSlideCanvasState();
}

class EditableSlideCanvasState extends State<EditableSlideCanvas> {
  String? _selectedElementId;
  final ValueNotifier<SlideElement?> _selectedElementNotifier =
      ValueNotifier<SlideElement?>(null);

  SlideData get _slide => widget.slide;

  ValueListenable<SlideElement?> get selectionNotifier =>
      _selectedElementNotifier;

  SlideElement? get selectedElement {
    final id = _selectedElementId;
    if (id == null) return null;
    for (final element in _slide.elements) {
      if (element.id == id) return element;
    }
    return null;
  }

  bool get hasSelection => _selectedElementId != null;

  bool get _selectedIsText => selectedElement?.type == SlideElementType.text;

  double? get selectedTextFontSize {
    if (!_selectedIsText) return null;
    final element = selectedElement;
    if (element == null) return null;
    return element.style.fontSize ?? 16;
  }

  void deleteSelectedElement() {
    final id = _selectedElementId;
    if (id == null) return;
    _deleteElement(id);
  }

  void setSelectedTextFontSize(double size) {
    final element = selectedElement;
    if (element == null || element.type != SlideElementType.text) return;

    final clamped = size
        .clamp(
          _EditableElementState.minFontSize,
          _EditableElementState.maxFontSize,
        )
        .toDouble();
    final updated = element.copyWith(
      style: element.style.copyWith(fontSize: clamped),
    );
    _updateElement(updated);
  }

  void nudgeSelectedTextFontSize(double delta) {
    final currentSize = selectedTextFontSize;
    if (currentSize == null) return;
    setSelectedTextFontSize(currentSize + delta);
  }

  @override
  void dispose() {
    _selectedElementNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EditableSlideCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedElementId != null) {
      final exists = _slide.elements.any(
        (element) => element.id == _selectedElementId,
      );
      if (!exists) {
        _selectedElementId = null;
        _notifySelection();
        return;
      }
    }
    _notifySelection();
  }

  void _notifySelection() {
    _selectedElementNotifier.value = selectedElement;
  }

  void _selectElement(String? elementId) {
    if (_selectedElementId == elementId) return;
    setState(() {
      _selectedElementId = elementId;
    });
    _notifySelection();
  }

  void _updateElement(SlideElement element) {
    final updatedSlide = _slide.updateElement(element.id, element);
    widget.onSlideUpdated(updatedSlide);
  }

  void _deleteElement(String elementId) {
    final updatedSlide = _slide.removeElement(elementId);
    widget.onSlideUpdated(updatedSlide);
    if (_selectedElementId == elementId) {
      setState(() {
        _selectedElementId = null;
      });
      _notifySelection();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> addTextElement() async {
    final result = await _showPromptDialog(
      context: context,
      title: '텍스트 추가',
      label: '텍스트 내용',
      confirmLabel: '추가',
    );

    if (result == null) return;

    final element = SlideElement.create(
      type: SlideElementType.text,
      data: {'text': result.isEmpty ? '새 텍스트' : result},
    );

    final updatedSlide = _slide.addElement(element);
    widget.onSlideUpdated(updatedSlide);
    setState(() {
      _selectedElementId = element.id;
    });
    _notifySelection();
  }

  Future<void> addImageElement() async {
    try {
      FilePicker filePicker;
      try {
        filePicker = FilePicker.platform;
      } catch (error) {
        final isLateInitError =
            error is Error &&
            error.toString().contains('LateInitializationError');
        if (isLateInitError || error is UnsupportedError) {
          _showMessage('현재 플랫폼에서는 로컬 이미지 선택을 지원하지 않습니다.');
          return;
        }
        rethrow;
      }

      final result = await filePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final Uint8List? bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage('선택한 이미지를 읽을 수 없습니다. 다른 파일을 시도해 주세요.');
        return;
      }

      final element = SlideElement.create(
        type: SlideElementType.image,
        data: {
          'source': 'local',
          'base64': base64Encode(bytes),
          'name': file.name,
        },
      );

      final updatedSlide = _slide.addElement(element);
      widget.onSlideUpdated(updatedSlide);
      setState(() {
        _selectedElementId = element.id;
      });
      _notifySelection();
    } catch (error, stackTrace) {
      _showMessage('이미지를 불러오는 중 오류가 발생했습니다.');
      debugPrint('Image picker error: $error\n$stackTrace');
    }
  }

  Future<String?> _editText(String initialValue) {
    return _showPromptDialog(
      context: context,
      title: '텍스트 편집',
      label: '내용',
      initialValue: initialValue,
      confirmLabel: '저장',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectElement(null),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white),
                  if (_slide.backgroundImagePath != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _slide.backgroundImagePath!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  for (final element in _slide.elements)
                    _EditableElement(
                      key: ValueKey(element.id),
                      element: element,
                      canvasSize: canvasSize,
                      isSelected: _selectedElementId == element.id,
                      onSelected: () => _selectElement(element.id),
                      onElementCommitted: _updateElement,
                      onDelete: () => _deleteElement(element.id),
                      onEditText: _editText,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EditableElement extends StatefulWidget {
  const _EditableElement({
    super.key,
    required this.element,
    required this.canvasSize,
    required this.isSelected,
    required this.onSelected,
    required this.onElementCommitted,
    required this.onDelete,
    required this.onEditText,
  });

  final SlideElement element;
  final Size canvasSize;
  final bool isSelected;
  final VoidCallback onSelected;
  final ValueChanged<SlideElement> onElementCommitted;
  final VoidCallback onDelete;
  final Future<String?> Function(String initialValue) onEditText;

  @override
  State<_EditableElement> createState() => _EditableElementState();
}

class _EditableElementState extends State<_EditableElement> {
  late ElementPosition _position;
  late ElementSize _size;

  static const double _minWidth = 60;
  static const double _minHeight = 40;
  static const double _epsilon = 0.1;
  static const double _textPadding = 12;
  static const double minFontSize = 12;
  static const double maxFontSize = 96;

  double? _fontSizeOverride;

  double get _elementFontSize => widget.element.style.fontSize ?? 18;

  double get _fontSize => _fontSizeOverride ?? _elementFontSize;

  bool get _isTextElement => widget.element.type == SlideElementType.text;

  @override
  void initState() {
    super.initState();
    _position = widget.element.position;
    _size = widget.element.size;

    if (_isTextElement) {
      _fontSizeOverride = _elementFontSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _autoSizeText(force: true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _EditableElement oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.element.position != widget.element.position) {
      _position = widget.element.position;
    }
    if (oldWidget.element.size != widget.element.size) {
      _size = widget.element.size;
    }

    if (_isTextElement) {
      final prevText = oldWidget.element.data['text']?.toString();
      final nextText = widget.element.data['text']?.toString();
      final nextFontSize = widget.element.style.fontSize;
      final prevFontSize = oldWidget.element.style.fontSize;

      if (_fontSizeOverride == null ||
          (nextFontSize != null && nextFontSize != _fontSizeOverride)) {
        _fontSizeOverride = nextFontSize ?? _fontSizeOverride;
      }

      final textChanged = prevText != nextText;
      final fontChanged = prevFontSize != nextFontSize;
      if (textChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _autoSizeText(force: true);
        });
      } else if (fontChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _autoSizeText(force: true);
        });
      }
    } else {
      _fontSizeOverride = null;
    }
  }

  void _handlePanStart(DragStartDetails details) {
    widget.onSelected();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final maxX = math.max(0.0, widget.canvasSize.width - _size.width);
    final maxY = math.max(0.0, widget.canvasSize.height - _size.height);
    final newX = (_position.x + details.delta.dx).clamp(0.0, maxX).toDouble();
    final newY = (_position.y + details.delta.dy).clamp(0.0, maxY).toDouble();

    setState(() {
      _position = _position.copyWith(x: newX, y: newY);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _commitPositionIfChanged();
  }

  void _handlePanCancel() {
    _commitPositionIfChanged();
  }

  void _handleResizeUpdate(DragUpdateDetails details) {
    final maxWidth = math.max(0.0, widget.canvasSize.width - _position.x);
    final maxHeight = math.max(0.0, widget.canvasSize.height - _position.y);
    final newWidth = (_size.width + details.delta.dx)
        .clamp(_minWidth, maxWidth)
        .toDouble();
    final newHeight = (_size.height + details.delta.dy)
        .clamp(_minHeight, maxHeight)
        .toDouble();

    setState(() {
      _size = _size.copyWith(width: newWidth, height: newHeight);
    });
  }

  void _handleResizeEnd(DragEndDetails details) {
    _commitSizeIfChanged();
  }

  void _commitPositionIfChanged() {
    final original = widget.element.position;
    if ((original.x - _position.x).abs() > _epsilon ||
        (original.y - _position.y).abs() > _epsilon) {
      widget.onElementCommitted(widget.element.copyWith(position: _position));
    } else {
      setState(() {
        _position = original;
      });
    }
  }

  void _commitSizeIfChanged() {
    final original = widget.element.size;
    if ((original.width - _size.width).abs() > _epsilon ||
        (original.height - _size.height).abs() > _epsilon) {
      widget.onElementCommitted(widget.element.copyWith(size: _size));
    } else {
      setState(() {
        _size = original;
      });
    }
  }

  Future<void> _handleDoubleTap() async {
    if (!_isTextElement) return;

    final currentText = widget.element.data['text']?.toString() ?? '';
    final result = await widget.onEditText(currentText);
    if (!mounted || result == null) return;

    final updatedElement = widget.element.copyWith(
      data: {...widget.element.data, 'text': result.isEmpty ? '새 텍스트' : result},
    );

    widget.onElementCommitted(updatedElement);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoSizeText(force: true);
    });
  }

  void _changeFontSize(double delta) {
    final current = _fontSize;
    final newSize = (current + delta)
        .clamp(minFontSize, maxFontSize)
        .toDouble();
    _setFontSize(newSize);
  }

  void _setFontSize(double newSize) {
    final clamped = newSize.clamp(minFontSize, maxFontSize).toDouble();
    if ((_fontSize - clamped).abs() < 0.1) return;

    setState(() {
      _fontSizeOverride = clamped;
    });

    final updatedElement = widget.element.copyWith(
      style: widget.element.style.copyWith(fontSize: clamped),
    );

    widget.onElementCommitted(updatedElement);
  }

  void _autoSizeText({bool force = false}) {
    if (!_isTextElement) return;

    final text = widget.element.data['text']?.toString() ?? '';
    final fontSize = _fontSize;

    if (text.isEmpty) {
      if (force) {
        const defaultSize = ElementSize(width: 200, height: 80);
        if (_size != defaultSize) {
          setState(() => _size = defaultSize);
          widget.onElementCommitted(widget.element.copyWith(size: defaultSize));
        }
      }
      return;
    }

    final computedSize = _calculateTextElementSize(text, fontSize);
    final differs =
        (computedSize.width - widget.element.size.width).abs() > _epsilon ||
        (computedSize.height - widget.element.size.height).abs() > _epsilon;

    if (force || differs) {
      setState(() => _size = computedSize);
      widget.onElementCommitted(widget.element.copyWith(size: computedSize));
    }
  }

  ElementSize _calculateTextElementSize(String text, double fontSize) {
    const frameBuffer = 8.0;
    final maxContentWidth = math.max(
      _minWidth.toDouble(),
      math.min(widget.canvasSize.width * 0.6, widget.canvasSize.width - 48),
    );

    final textStyle = _textStyleForElement(widget.element, fontSize);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: _textAlignFromString(widget.element.style.textAlign),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxContentWidth - (_textPadding * 2));

    final lineMetrics = textPainter.computeLineMetrics();
    final longestLineWidth = lineMetrics.isEmpty
        ? textPainter.width
        : lineMetrics.map((metric) => metric.width).fold<double>(0, math.max);

    final contentWidth = math.min(longestLineWidth, maxContentWidth);
    final contentHeight = textPainter.height;

    final width = contentWidth + (_textPadding * 2) + frameBuffer;
    final height = contentHeight + (_textPadding * 2) + frameBuffer;

    final clampedWidth = width.clamp(
      _minWidth.toDouble(),
      widget.canvasSize.width - 24,
    );
    final clampedHeight = height.clamp(
      _minHeight.toDouble(),
      widget.canvasSize.height - 24,
    );

    return ElementSize(width: clampedWidth, height: clampedHeight);
  }

  TextStyle _textStyleForElement(SlideElement element, double fontSize) {
    final style = element.style;
    final fontWeight = switch (style.fontWeight) {
      'bold' => FontWeight.bold,
      'w600' => FontWeight.w600,
      'w500' => FontWeight.w500,
      'light' => FontWeight.w300,
      _ => FontWeight.normal,
    };

    return TextStyle(
      fontSize: fontSize,
      fontFamily: style.fontFamily,
      fontWeight: fontWeight,
      height: 1.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    final child = _buildContent(context, element);
    final isTextElement = _isTextElement;

    return Positioned(
      left: _position.x,
      top: _position.y,
      width: _size.width,
      height: _size.height,
      child: GestureDetector(
        onTap: widget.onSelected,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: _handlePanCancel,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: widget.isSelected
                      ? Border.all(color: AppTheme.primaryColor, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(
                    element.style.borderRadius ?? 0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    element.style.borderRadius ?? 0,
                  ),
                  child: child,
                ),
              ),
            ),
            if (widget.isSelected && !isTextElement)
              Positioned(
                right: -8,
                bottom: -8,
                child: _ResizeHandle(
                  onPanUpdate: _handleResizeUpdate,
                  onPanEnd: _handleResizeEnd,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SlideElement element) {
    switch (element.type) {
      case SlideElementType.text:
        final text = element.data['text']?.toString() ?? '';
        final color = _colorFromHex(
          element.style.color,
          fallback: AppTheme.textPrimaryColor,
        );
        final fontSize = element.style.fontSize ?? 18.0;
        final fontWeight = element.style.fontWeight == 'bold'
            ? FontWeight.bold
            : FontWeight.normal;
        final textAlign = _textAlignFromString(element.style.textAlign);
        return Container(
          padding: const EdgeInsets.all(_textPadding),
          alignment: Alignment.topLeft,
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: 1.4,
            ),
            textAlign: textAlign,
          ),
        );
      case SlideElementType.image:
        final data = element.data;
        final source = data['source']?.toString();

        if (source == 'local' && data['base64'] is String) {
          try {
            final bytes = base64Decode(data['base64'] as String);
            return Container(
              color: Colors.black.withValues(alpha: 0.04),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            );
          } catch (_) {
            return _imagePlaceholder('로컬 이미지를 해석하지 못했습니다');
          }
        }

        final imageUrl = data['url']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Container(
            color: Colors.black.withValues(alpha: 0.04),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            ),
          );
        }

        return _imagePlaceholder();
      default:
        return Container(
          color: AppTheme.surfaceColor.withValues(alpha: 0.6),
          alignment: Alignment.center,
          child: Text(
            '${element.type.name} 요소 편집은 곧 지원됩니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        );
    }
  }

  Widget _imagePlaceholder([String? subtitle]) {
    return Container(
      color: AppTheme.surfaceColor.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, color: Colors.white70),
          const SizedBox(height: 8),
          Text(
            subtitle ?? '이미지를 불러올 수 없습니다',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onPanUpdate, required this.onPanEnd});

  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
      ),
    );
  }
}

Future<String?> _showPromptDialog({
  required BuildContext context,
  required String title,
  required String label,
  String? initialValue,
  String? hintText,
  String confirmLabel = '확인',
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _PromptDialog(
        title: title,
        label: label,
        initialValue: initialValue ?? '',
        hintText: hintText,
        confirmLabel: confirmLabel,
      );
    },
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    this.hintText,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String initialValue;
  final String? hintText;
  final String confirmLabel;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
        ),
        minLines: 1,
        maxLines: 8,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

TextAlign _textAlignFromString(String? value) {
  switch (value) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    default:
      return TextAlign.left;
  }
}

Color _colorFromHex(String? hex, {required Color fallback}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return fallback;
}
