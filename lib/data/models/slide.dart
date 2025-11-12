import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../utils/json_date_parser.dart';

/// 슬라이드 데이터 모델
class SlideData {
  final String id;
  final String title;
  final List<SlideElement> elements;
  final Duration duration;
  final SlideLayout layout;
  final SlideStyle style;
  final String? backgroundImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order;
  final String? speakerNotes;
  final Map<String, dynamic> metadata;

  const SlideData({
    required this.id,
    required this.title,
    required this.elements,
    required this.duration,
    required this.layout,
    required this.style,
    this.backgroundImagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
    this.speakerNotes,
    this.metadata = const {},
  });

  /// 새 슬라이드 생성
  factory SlideData.create({
    required String title,
    required int order,
    SlideLayout? layout,
  }) {
    final now = DateTime.now();
    return SlideData(
      id: const Uuid().v4(),
      title: title,
      elements: [],
      duration: const Duration(seconds: 10),
      layout: layout ?? SlideLayout.titleAndContent,
      style: SlideStyle.defaultStyle(),
      createdAt: now,
      updatedAt: now,
      order: order,
    );
  }

  /// 슬라이드 복사
  SlideData copyWith({
    String? title,
    List<SlideElement>? elements,
    Duration? duration,
    SlideLayout? layout,
    SlideStyle? style,
    String? backgroundImagePath,
    DateTime? updatedAt,
    int? order,
    String? speakerNotes,
    Map<String, dynamic>? metadata,
  }) {
    return SlideData(
      id: id,
      title: title ?? this.title,
      elements: elements ?? this.elements,
      duration: duration ?? this.duration,
      layout: layout ?? this.layout,
      style: style ?? this.style,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      order: order ?? this.order,
      speakerNotes: speakerNotes ?? this.speakerNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'elements': elements.map((element) => element.toJson()).toList(),
      'duration': duration.inSeconds,
      'layout': layout.name,
      'style': style.toJson(),
      'backgroundImagePath': backgroundImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order': order,
      'speakerNotes': speakerNotes,
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory SlideData.fromJson(Map<String, dynamic> json) {
    return SlideData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      elements: (json['elements'] as List? ?? [])
          .map(
            (element) => SlideElement.fromJson(element as Map<String, dynamic>),
          )
          .toList(),
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      layout: SlideLayout.values.firstWhere(
        (layout) => layout.name == json['layout'],
        orElse: () => SlideLayout.titleAndContent,
      ),
      style: json['style'] != null
          ? SlideStyle.fromJson(json['style'] as Map<String, dynamic>)
          : SlideStyle.defaultStyle(),
      backgroundImagePath: json['backgroundImagePath'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      order: json['order'] as int? ?? 0,
      speakerNotes: json['speakerNotes'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 완료 여부 (모든 요소가 설정됨)
  bool get isCompleted {
    return title.isNotEmpty && elements.isNotEmpty;
  }

  /// 요소 추가
  SlideData addElement(SlideElement element) {
    return copyWith(
      elements: [...elements, element],
      updatedAt: DateTime.now(),
    );
  }

  /// 요소 제거
  SlideData removeElement(String elementId) {
    return copyWith(
      elements: elements.where((element) => element.id != elementId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 요소 업데이트
  SlideData updateElement(String elementId, SlideElement updatedElement) {
    final updatedElements = elements.map((element) {
      return element.id == elementId ? updatedElement : element;
    }).toList();

    return copyWith(elements: updatedElements, updatedAt: DateTime.now());
  }

  /// 요소 순서 변경
  SlideData reorderElements(int oldIndex, int newIndex) {
    final updatedElements = List<SlideElement>.from(elements);
    final element = updatedElements.removeAt(oldIndex);
    updatedElements.insert(newIndex, element);

    return copyWith(elements: updatedElements, updatedAt: DateTime.now());
  }
}

/// 슬라이드 요소
class SlideElement {
  final String id;
  final SlideElementType type;
  final Map<String, dynamic> data;
  final ElementPosition position;
  final ElementSize size;
  final ElementStyle style;
  final bool isLocked;
  final int zIndex;

  const SlideElement({
    required this.id,
    required this.type,
    required this.data,
    required this.position,
    required this.size,
    required this.style,
    this.isLocked = false,
    this.zIndex = 0,
  });

  /// 새 요소 생성
  factory SlideElement.create({
    required SlideElementType type,
    required Map<String, dynamic> data,
    ElementPosition? position,
    ElementSize? size,
  }) {
    return SlideElement(
      id: const Uuid().v4(),
      type: type,
      data: data,
      position: position ?? const ElementPosition(x: 100, y: 100),
      size: size ?? ElementSize.fromType(type),
      style: ElementStyle.defaultForType(type),
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'position': position.toJson(),
      'size': size.toJson(),
      'style': style.toJson(),
      'isLocked': isLocked,
      'zIndex': zIndex,
    };
  }

  /// JSON에서 생성
  factory SlideElement.fromJson(Map<String, dynamic> json) {
    return SlideElement(
      id: json['id'] as String,
      type: SlideElementType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => SlideElementType.text,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      position: ElementPosition.fromJson(
        json['position'] as Map<String, dynamic>,
      ),
      size: ElementSize.fromJson(json['size'] as Map<String, dynamic>),
      style: ElementStyle.fromJson(json['style'] as Map<String, dynamic>),
      isLocked: json['isLocked'] as bool? ?? false,
      zIndex: json['zIndex'] as int? ?? 0,
    );
  }

  /// 요소 복사
  SlideElement copyWith({
    SlideElementType? type,
    Map<String, dynamic>? data,
    ElementPosition? position,
    ElementSize? size,
    ElementStyle? style,
    bool? isLocked,
    int? zIndex,
  }) {
    return SlideElement(
      id: id,
      type: type ?? this.type,
      data: data ?? this.data,
      position: position ?? this.position,
      size: size ?? this.size,
      style: style ?? this.style,
      isLocked: isLocked ?? this.isLocked,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}

/// 요소 위치
class ElementPosition {
  final double x;
  final double y;

  const ElementPosition({required this.x, required this.y});

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }

  factory ElementPosition.fromJson(Map<String, dynamic> json) {
    return ElementPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  ElementPosition copyWith({double? x, double? y}) {
    return ElementPosition(x: x ?? this.x, y: y ?? this.y);
  }
}

/// 요소 크기
class ElementSize {
  final double width;
  final double height;

  const ElementSize({required this.width, required this.height});

  /// 타입별 기본 크기
  factory ElementSize.fromType(SlideElementType type) {
    switch (type) {
      case SlideElementType.text:
        return const ElementSize(width: 400, height: 100);
      case SlideElementType.image:
        return const ElementSize(width: 300, height: 200);
      case SlideElementType.chart:
        return const ElementSize(width: 500, height: 300);
      case SlideElementType.table:
        return const ElementSize(width: 600, height: 200);
      case SlideElementType.icon:
        return const ElementSize(width: 50, height: 50);
      case SlideElementType.shape:
        return const ElementSize(width: 200, height: 100);
      case SlideElementType.video:
        return const ElementSize(width: 400, height: 225);
      case SlideElementType.background:
        return const ElementSize(width: 800, height: 600);
      case SlideElementType.animation:
        return const ElementSize(width: 200, height: 200);
    }
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }

  factory ElementSize.fromJson(Map<String, dynamic> json) {
    return ElementSize(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  ElementSize copyWith({double? width, double? height}) {
    return ElementSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  double get aspectRatio => width / height;
}

/// 요소 스타일
class ElementStyle {
  final String? fontFamily;
  final double? fontSize;
  final String? fontWeight;
  final String? color;
  final String? backgroundColor;
  final double? borderWidth;
  final String? borderColor;
  final double? borderRadius;
  final double? opacity;
  final String? textAlign;
  final Map<String, dynamic> customProperties;

  const ElementStyle({
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.backgroundColor,
    this.borderWidth,
    this.borderColor,
    this.borderRadius,
    this.opacity,
    this.textAlign,
    this.customProperties = const {},
  });

  /// 타입별 기본 스타일
  factory ElementStyle.defaultForType(SlideElementType type) {
    switch (type) {
      case SlideElementType.text:
        return const ElementStyle(
          fontSize: 16,
          fontWeight: 'normal',
          color: '#000000',
          textAlign: 'left',
        );
      case SlideElementType.image:
        return const ElementStyle(borderRadius: 8, opacity: 1.0);
      case SlideElementType.chart:
        return const ElementStyle(
          backgroundColor: '#ffffff',
          borderWidth: 1,
          borderColor: '#e0e0e0',
          borderRadius: 8,
        );
      case SlideElementType.table:
        return const ElementStyle(
          backgroundColor: '#ffffff',
          borderWidth: 1,
          borderColor: '#e0e0e0',
        );
      case SlideElementType.icon:
        return const ElementStyle(color: '#333333', opacity: 1.0);
      case SlideElementType.shape:
        return const ElementStyle(
          backgroundColor: '#007ACC',
          borderRadius: 4,
          opacity: 1.0,
        );
      case SlideElementType.video:
        return const ElementStyle(borderRadius: 8, opacity: 1.0);
      case SlideElementType.background:
        return const ElementStyle(opacity: 1.0);
      case SlideElementType.animation:
        return const ElementStyle(opacity: 1.0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'color': color,
      'backgroundColor': backgroundColor,
      'borderWidth': borderWidth,
      'borderColor': borderColor,
      'borderRadius': borderRadius,
      'opacity': opacity,
      'textAlign': textAlign,
      'customProperties': customProperties,
    };
  }

  factory ElementStyle.fromJson(Map<String, dynamic> json) {
    return ElementStyle(
      fontFamily: json['fontFamily'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontWeight: json['fontWeight'] as String?,
      color: json['color'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
      borderColor: json['borderColor'] as String?,
      borderRadius: (json['borderRadius'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
      textAlign: json['textAlign'] as String?,
      customProperties: Map<String, dynamic>.from(
        json['customProperties'] ?? {},
      ),
    );
  }

  ElementStyle copyWith({
    String? fontFamily,
    double? fontSize,
    String? fontWeight,
    String? color,
    String? backgroundColor,
    double? borderWidth,
    String? borderColor,
    double? borderRadius,
    double? opacity,
    String? textAlign,
    Map<String, dynamic>? customProperties,
  }) {
    return ElementStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      opacity: opacity ?? this.opacity,
      textAlign: textAlign ?? this.textAlign,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}

/// 슬라이드 레이아웃
enum SlideLayout {
  titleOnly('제목만'),
  titleAndContent('제목과 내용'),
  twoColumns('두 열'),
  comparison('비교'),
  imageAndText('이미지와 텍스트'),
  fullImage('전체 이미지'),
  chart('차트'),
  table('표'),
  timeline('타임라인'),
  process('프로세스');

  const SlideLayout(this.displayName);
  final String displayName;
}

// SlideElementType은 app_constants.dart에서 import하여 사용

/// 슬라이드 스타일
class SlideStyle {
  final String colorScheme;
  final String fontFamily;
  final Map<String, dynamic> colors;
  final Map<String, dynamic> typography;
  final Map<String, dynamic> spacing;

  const SlideStyle({
    required this.colorScheme,
    required this.fontFamily,
    required this.colors,
    required this.typography,
    required this.spacing,
  });

  factory SlideStyle.defaultStyle() {
    return const SlideStyle(
      colorScheme: 'professional',
      fontFamily: 'Inter',
      colors: {
        'primary': '#007ACC',
        'secondary': '#6B7280',
        'background': '#FFFFFF',
        'text': '#1F2937',
        'accent': '#3B82F6',
      },
      typography: {
        'heading1': {'fontSize': 32, 'fontWeight': 'bold'},
        'heading2': {'fontSize': 24, 'fontWeight': '600'},
        'body': {'fontSize': 16, 'fontWeight': 'normal'},
        'caption': {'fontSize': 12, 'fontWeight': 'normal'},
      },
      spacing: {'small': 8, 'medium': 16, 'large': 24, 'xlarge': 32},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorScheme': colorScheme,
      'fontFamily': fontFamily,
      'colors': colors,
      'typography': typography,
      'spacing': spacing,
    };
  }

  factory SlideStyle.fromJson(Map<String, dynamic> json) {
    return SlideStyle(
      colorScheme: json['colorScheme'] as String,
      fontFamily: json['fontFamily'] as String,
      colors: Map<String, dynamic>.from(json['colors'] ?? {}),
      typography: Map<String, dynamic>.from(json['typography'] ?? {}),
      spacing: Map<String, dynamic>.from(json['spacing'] ?? {}),
    );
  }
}
