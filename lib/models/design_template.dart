import 'package:flutter/material.dart';

/// 디자인 템플릿의 색상 스키마
class ColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;

  const ColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
  });

  Map<String, dynamic> toJson() {
    return {
      'primary': primary.toARGB32(),
      'secondary': secondary.toARGB32(),
      'accent': accent.toARGB32(),
      'background': background.toARGB32(),
      'surface': surface.toARGB32(),
      'text': text.toARGB32(),
      'textSecondary': textSecondary.toARGB32(),
    };
  }

  factory ColorScheme.fromJson(Map<String, dynamic> json) {
    return ColorScheme(
      primary: Color(json['primary']),
      secondary: Color(json['secondary']),
      accent: Color(json['accent']),
      background: Color(json['background']),
      surface: Color(json['surface']),
      text: Color(json['text']),
      textSecondary: Color(json['textSecondary']),
    );
  }
}

/// 타이포그래피 설정
class Typography {
  final String titleFontFamily;
  final String bodyFontFamily;
  final double titleFontSize;
  final double bodyFontSize;
  final FontWeight titleFontWeight;
  final FontWeight bodyFontWeight;
  final double? subtitleFontSize;
  final FontWeight? subtitleFontWeight;

  const Typography({
    required this.titleFontFamily,
    required this.bodyFontFamily,
    required this.titleFontSize,
    required this.bodyFontSize,
    required this.titleFontWeight,
    required this.bodyFontWeight,
    this.subtitleFontSize,
    this.subtitleFontWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'titleFontFamily': titleFontFamily,
      'bodyFontFamily': bodyFontFamily,
      'titleFontSize': titleFontSize,
      'bodyFontSize': bodyFontSize,
      'titleFontWeight': titleFontWeight.index,
      'bodyFontWeight': bodyFontWeight.index,
      'subtitleFontSize': subtitleFontSize,
      'subtitleFontWeight': subtitleFontWeight?.index,
    };
  }

  factory Typography.fromJson(Map<String, dynamic> json) {
    return Typography(
      titleFontFamily: json['titleFontFamily'],
      bodyFontFamily: json['bodyFontFamily'],
      titleFontSize: json['titleFontSize'].toDouble(),
      bodyFontSize: json['bodyFontSize'].toDouble(),
      titleFontWeight: FontWeight.values[json['titleFontWeight']],
      bodyFontWeight: FontWeight.values[json['bodyFontWeight']],
      subtitleFontSize: json['subtitleFontSize']?.toDouble(),
      subtitleFontWeight: json['subtitleFontWeight'] != null 
          ? FontWeight.values[json['subtitleFontWeight']] 
          : null,
    );
  }
}

/// 배경 스타일
class BackgroundStyle {
  final String type; // 'solid', 'gradient', 'image'
  final Color? solidColor;
  final List<Color>? gradientColors;
  final String? imageUrl;
  final double? opacity;

  const BackgroundStyle({
    required this.type,
    this.solidColor,
    this.gradientColors,
    this.imageUrl,
    this.opacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'solidColor': solidColor?.toARGB32(),
      'gradientColors': gradientColors?.map((c) => c.toARGB32()).toList(),
      'imageUrl': imageUrl,
      'opacity': opacity,
    };
  }

  factory BackgroundStyle.fromJson(Map<String, dynamic> json) {
    return BackgroundStyle(
      type: json['type'],
      solidColor: json['solidColor'] != null ? Color(json['solidColor']) : null,
      gradientColors: json['gradientColors'] != null 
          ? (json['gradientColors'] as List).map((c) => Color(c)).toList()
          : null,
      imageUrl: json['imageUrl'],
      opacity: json['opacity']?.toDouble(),
    );
  }
}

/// 슬라이드 레이아웃
class SlideLayout {
  final String id;
  final String name;
  final String description;
  final List<ElementPlaceholder> placeholders;
  final ColorScheme colorScheme;
  final Typography typography;
  final BackgroundStyle background;

  const SlideLayout({
    required this.id,
    required this.name,
    required this.description,
    required this.placeholders,
    required this.colorScheme,
    required this.typography,
    required this.background,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'placeholders': placeholders.map((p) => p.toJson()).toList(),
      'colorScheme': colorScheme.toJson(),
      'typography': typography.toJson(),
      'background': background.toJson(),
    };
  }

  factory SlideLayout.fromJson(Map<String, dynamic> json) {
    return SlideLayout(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      placeholders: (json['placeholders'] as List)
          .map((p) => ElementPlaceholder.fromJson(p))
          .toList(),
      colorScheme: ColorScheme.fromJson(json['colorScheme']),
      typography: Typography.fromJson(json['typography']),
      background: BackgroundStyle.fromJson(json['background']),
    );
  }
}

/// 요소 플레이스홀더
class ElementPlaceholder {
  final String id;
  final String type; // 'title', 'content', 'image', 'chart', 'bullet_list'
  final Offset position;
  final Size size;
  final Map<String, dynamic> properties;

  const ElementPlaceholder({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.properties = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'properties': properties,
    };
  }

  factory ElementPlaceholder.fromJson(Map<String, dynamic> json) {
    return ElementPlaceholder(
      id: json['id'],
      type: json['type'],
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }
}

/// 디자인 템플릿
class DesignTemplate {
  final String id;
  final String name;
  final String category; // 'business', 'creative', 'minimal', 'modern', 'academic'
  final String description;
  final String previewImage;
  final List<String> tags;
  final List<SlideLayout> layouts;
  final Map<String, dynamic> designRules;
  final BackgroundStyle? backgroundStyle;
  final ColorScheme? colorScheme;
  final bool isPremium;

  const DesignTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.previewImage,
    required this.tags,
    required this.layouts,
    required this.designRules,
    this.backgroundStyle,
    this.colorScheme,
    this.isPremium = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'previewImage': previewImage,
      'tags': tags,
      'layouts': layouts.map((l) => l.toJson()).toList(),
      'designRules': designRules,
      'backgroundStyle': backgroundStyle?.toJson(),
      'colorScheme': colorScheme?.toJson(),
      'isPremium': isPremium,
    };
  }

  factory DesignTemplate.fromJson(Map<String, dynamic> json) {
    return DesignTemplate(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      previewImage: json['previewImage'],
      tags: List<String>.from(json['tags']),
      layouts: (json['layouts'] as List)
          .map((l) => SlideLayout.fromJson(l))
          .toList(),
      designRules: Map<String, dynamic>.from(json['designRules']),
      backgroundStyle: json['backgroundStyle'] != null 
          ? BackgroundStyle.fromJson(json['backgroundStyle']) 
          : null,
      colorScheme: json['colorScheme'] != null 
          ? ColorScheme.fromJson(json['colorScheme']) 
          : null,
      isPremium: json['isPremium'] ?? false,
    );
  }

  /// 카테고리별 필터링을 위한 getter
  bool get isBusiness => category == 'business';
  bool get isCreative => category == 'creative';
  bool get isMinimal => category == 'minimal';
  bool get isModern => category == 'modern';
  bool get isAcademic => category == 'academic';

  /// 태그 검색을 위한 메서드
  bool hasTag(String tag) {
    return tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()));
  }

  /// 카테고리별 색상 반환
  Color get categoryColor {
    switch (category) {
      case 'business':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'minimal':
        return Colors.grey;
      case 'modern':
        return Colors.teal;
      case 'academic':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
