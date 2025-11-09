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
  State<EditableSlideCanvas> createState() => _EditableSlideCanvasState();
}

class _EditableSlideCanvasState extends State<EditableSlideCanvas> {
  String? _selectedElementId;

  SlideData get _slide => widget.slide;

  @override
  void didUpdateWidget(covariant EditableSlideCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedElementId != null) {
      final exists = _slide.elements
          .any((element) => element.id == _selectedElementId);
      if (!exists) {
        _selectedElementId = null;
      }
    }
  }

  void _selectElement(String? elementId) {
    if (_selectedElementId == elementId) return;
    setState(() {
      _selectedElementId = elementId;
    });
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

  Future<void> _addTextElement() async {
    final result = await _showPromptDialog(
      context: context,
      title: '텍스트 추가',
      label: '텍스트 내용',
      confirmLabel: '추가',
    );

    if (result == null) return;

    final element = SlideElement.create(
      type: SlideElementType.text,
      data: {
        'text': result.isEmpty ? '새 텍스트' : result,
      },
    );

    final updatedSlide = _slide.addElement(element);
    widget.onSlideUpdated(updatedSlide);
    setState(() {
      _selectedElementId = element.id;
    });
  }

  Future<void> _addImageElement() async {
    try {
      FilePicker filePicker;
      try {
        filePicker = FilePicker.platform;
      } catch (error) {
        final isLateInitError =
            error is Error && error.toString().contains('LateInitializationError');
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
        Positioned(
          top: 16,
          right: 16,
          child: _CanvasToolbar(
            onAddText: _addTextElement,
            onAddImage: _addImageElement,
            hasSelection: _selectedElementId != null,
            onDeleteSelected: _selectedElementId == null
                ? null
                : () => _deleteElement(_selectedElementId!),
          ),
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
  static const double _minFontSize = 12;
  static const double _maxFontSize = 96;

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

      if (_fontSizeOverride == null || (nextFontSize != null && nextFontSize != _fontSizeOverride)) {
        _fontSizeOverride = nextFontSize ?? _fontSizeOverride;
      }

      final textChanged = prevText != nextText;
      if (textChanged) {
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
    final newWidth =
        (_size.width + details.delta.dx).clamp(_minWidth, maxWidth).toDouble();
    final newHeight =
        (_size.height + details.delta.dy).clamp(_minHeight, maxHeight).toDouble();

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
      widget.onElementCommitted(
        widget.element.copyWith(position: _position),
      );
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
      widget.onElementCommitted(
        widget.element.copyWith(size: _size),
      );
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
      data: {
        ...widget.element.data,
        'text': result.isEmpty ? '새 텍스트' : result,
      },
    );

    widget.onElementCommitted(updatedElement);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoSizeText(force: true);
    });
  }

  void _changeFontSize(double delta) {
    final current = _fontSize;
    final newSize = (current + delta).clamp(_minFontSize, _maxFontSize).toDouble();
    _setFontSize(newSize);
  }

  void _setFontSize(double newSize) {
    final clamped = newSize.clamp(_minFontSize, _maxFontSize).toDouble();
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
        final defaultSize = ElementSize(width: 200, height: 80);
        if (_size != defaultSize) {
          setState(() {
            _size = defaultSize;
          });
          widget.onElementCommitted(
            widget.element.copyWith(size: defaultSize),
          );
        }
      }
      return;
    }

    final computedSize = _calculateTextElementSize(text, fontSize);
    final differs =
        (computedSize.width - widget.element.size.width).abs() > _epsilon ||
            (computedSize.height - widget.element.size.height).abs() > _epsilon;

    if (force || differs) {
      setState(() {
        _size = computedSize;
      });
      widget.onElementCommitted(
        widget.element.copyWith(size: computedSize),
      );
    }
  }

  ElementSize _calculateTextElementSize(String text, double fontSize) {
    final maxContentWidth = math.max(
      _minWidth.toDouble(),
      math.min(widget.canvasSize.width * 0.6, widget.canvasSize.width - 40),
    );

    final textStyle = _textStyleForElement(widget.element, fontSize);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: _textAlignFromString(widget.element.style.textAlign),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxContentWidth - (_textPadding * 2));

    final width = textPainter.width + (_textPadding * 2);
    final height = textPainter.height + (_textPadding * 2);

    final clampedWidth = width.clamp(_minWidth.toDouble(), widget.canvasSize.width - 24);
    final clampedHeight = height.clamp(_minHeight.toDouble(), widget.canvasSize.height - 24);

    return ElementSize(
      width: clampedWidth,
      height: clampedHeight,
    );
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
    final hasFontToolbar = widget.isSelected && _isTextElement;
    const toolbarHeight = 40.0;
    const toolbarMinWidth = 140.0;

    double containerWidth = _size.width;
    double containerLeft = _position.x;

    final maxLeftForCurrentWidth =
        math.max(0.0, widget.canvasSize.width - containerWidth);
    containerLeft = containerLeft.clamp(0.0, maxLeftForCurrentWidth);

    double toolbarWidth = toolbarMinWidth;
    double toolbarLeft = 0;

    if (hasFontToolbar) {
      final neededWidth = math.max(toolbarMinWidth, _size.width);
      final maxLeft = math.max(0.0, widget.canvasSize.width - neededWidth);
      containerLeft = containerLeft.clamp(0.0, maxLeft);
      containerWidth = neededWidth;

      if (containerWidth < toolbarMinWidth) {
        containerWidth = toolbarMinWidth;
        containerLeft = containerLeft.clamp(
          0.0,
          math.max(0.0, widget.canvasSize.width - containerWidth),
        );
      }

      toolbarWidth = toolbarMinWidth;
      toolbarLeft = 0;
    }

    final elementOffsetLeft = (_position.x - containerLeft)
        .clamp(0.0, containerWidth - _size.width);

    final positionedTop = hasFontToolbar ? _position.y - toolbarHeight : _position.y;
    final positionedHeight = hasFontToolbar ? _size.height + toolbarHeight : _size.height;

    return Positioned(
      left: containerLeft,
      top: positionedTop,
      width: containerWidth,
      height: positionedHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: hasFontToolbar ? toolbarHeight : 0,
            left: elementOffsetLeft,
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
                            ? Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              )
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
                  if (widget.isSelected)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: _DeleteHandle(onDelete: widget.onDelete),
                    ),
                  if (widget.isSelected)
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
          ),
          if (hasFontToolbar)
            Positioned(
              top: 0,
              left: toolbarLeft,
              width: toolbarWidth,
              height: toolbarHeight,
              child: _FontSizeToolbar(
                fontSize: _fontSize,
                onDecrease: () => _changeFontSize(-2),
                onIncrease: () => _changeFontSize(2),
                onSet: _setFontSize,
              ),
            ),
        ],
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DeleteHandle extends StatelessWidget {
  const _DeleteHandle({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.close,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onPanUpdate,
    required this.onPanEnd,
  });

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
        child: const Icon(
          Icons.open_in_full,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.onAddText,
    required this.onAddImage,
    required this.hasSelection,
    this.onDeleteSelected,
  });

  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  final bool hasSelection;
  final VoidCallback? onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.text_fields,
              label: '텍스트 추가',
              onPressed: onAddText,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.image_outlined,
              label: '이미지 추가',
              onPressed: onAddImage,
            ),
            if (hasSelection && onDeleteSelected != null) ...[
              const SizedBox(width: 12),
              _ToolbarButton(
                icon: Icons.delete_outline,
                label: '선택 삭제',
                onPressed: onDeleteSelected!,
                color: Colors.redAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: effectiveColor,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
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

class _FontSizeToolbar extends StatefulWidget {
  const _FontSizeToolbar({
    required this.fontSize,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSet,
  });

  final double fontSize;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<double> onSet;

  @override
  State<_FontSizeToolbar> createState() => _FontSizeToolbarState();
}

class _FontSizeToolbarState extends State<_FontSizeToolbar> {
  static const double _buttonWidth = 40;
  static const double _fieldWidth = 64;
  bool _isEditing = false;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.fontSize));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _FontSizeToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.fontSize != widget.fontSize) {
      _controller.text = _format(widget.fontSize);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submit();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller
        ..text = _format(widget.fontSize)
        ..selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    final parsed = double.tryParse(text);
    if (parsed != null) {
      widget.onSet(parsed);
    } else {
      _controller.text = _format(widget.fontSize);
    }
    setState(() {
      _isEditing = false;
    });
  }

  String _format(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FontSizeButton(
              icon: Icons.remove,
              width: _buttonWidth,
              onPressed: widget.onDecrease,
            ),
            SizedBox(
              width: _fieldWidth,
              height: 28,
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      cursorColor: Colors.white,
                      onSubmitted: (_) => _submit(),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _startEditing,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          '${_format(widget.fontSize)}pt',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
            _FontSizeButton(
              icon: Icons.add,
              width: _buttonWidth,
              onPressed: widget.onIncrease,
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  const _FontSizeButton({
    required this.icon,
    required this.onPressed,
    required this.width,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {},
      onPanDown: (_) {},
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: 32,
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

