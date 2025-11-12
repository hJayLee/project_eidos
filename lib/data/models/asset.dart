import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../utils/json_date_parser.dart';

/// 에셋 라이브러리 모델
class Asset {
  final String id;
  final String name;
  final String originalFileName;
  final String filePath;
  final MediaType type;
  final int fileSize;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime lastUsed;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const Asset({
    required this.id,
    required this.name,
    required this.originalFileName,
    required this.filePath,
    required this.type,
    required this.fileSize,
    this.thumbnailPath,
    required this.createdAt,
    required this.lastUsed,
    this.tags = const [],
    this.metadata = const {},
  });

  /// 새 에셋 생성
  factory Asset.create({
    required String name,
    required String originalFileName,
    required String filePath,
    required MediaType type,
    required int fileSize,
    String? thumbnailPath,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return Asset(
      id: const Uuid().v4(),
      name: name,
      originalFileName: originalFileName,
      filePath: filePath,
      type: type,
      fileSize: fileSize,
      thumbnailPath: thumbnailPath,
      createdAt: now,
      lastUsed: now,
      tags: tags ?? [],
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalFileName': originalFileName,
      'filePath': filePath,
      'type': type.id,
      'fileSize': fileSize,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      originalFileName: json['originalFileName'] as String,
      filePath: json['filePath'] as String,
      type: MediaType.values.firstWhere(
        (type) => type.id == json['type'],
        orElse: () => MediaType.image,
      ),
      fileSize: json['fileSize'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      lastUsed: parseDateTime(json['lastUsed']),
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 에셋 복사
  Asset copyWith({
    String? name,
    String? filePath,
    String? thumbnailPath,
    DateTime? lastUsed,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      originalFileName: originalFileName,
      filePath: filePath ?? this.filePath,
      type: type,
      fileSize: fileSize,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt,
      lastUsed: lastUsed ?? DateTime.now(),
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 파일 크기 표시용 텍스트
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 파일 확장자
  String get fileExtension {
    return originalFileName.split('.').last.toLowerCase();
  }
}

/// 브랜드 키트 모델
class BrandKit {
  final String id;
  final String name;
  final BrandColors colors;
  final BrandFonts fonts;
  final String? logoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  const BrandKit({
    required this.id,
    required this.name,
    required this.colors,
    required this.fonts,
    this.logoPath,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  /// 기본 브랜드 키트
  factory BrandKit.defaultKit() {
    final now = DateTime.now();
    return BrandKit(
      id: 'default',
      name: '기본 브랜드',
      colors: BrandColors.defaultColors(),
      fonts: BrandFonts.defaultFonts(),
      createdAt: now,
      updatedAt: now,
      isDefault: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colors': colors.toJson(),
      'fonts': fonts.toJson(),
      'logoPath': logoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory BrandKit.fromJson(Map<String, dynamic> json) {
    return BrandKit(
      id: json['id'] as String,
      name: json['name'] as String,
      colors: BrandColors.fromJson(json['colors'] as Map<String, dynamic>),
      fonts: BrandFonts.fromJson(json['fonts'] as Map<String, dynamic>),
      logoPath: json['logoPath'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// 브랜드 컬러
class BrandColors {
  final String primary;
  final String secondary;
  final String accent;
  final String background;
  final String surface;
  final String text;
  final String textSecondary;

  const BrandColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
  });

  factory BrandColors.defaultColors() {
    return const BrandColors(
      primary: '#007ACC',
      secondary: '#6B7280',
      accent: '#3B82F6',
      background: '#FFFFFF',
      surface: '#F8FAFC',
      text: '#1F2937',
      textSecondary: '#6B7280',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
      'background': background,
      'surface': surface,
      'text': text,
      'textSecondary': textSecondary,
    };
  }

  factory BrandColors.fromJson(Map<String, dynamic> json) {
    return BrandColors(
      primary: json['primary'] as String,
      secondary: json['secondary'] as String,
      accent: json['accent'] as String,
      background: json['background'] as String,
      surface: json['surface'] as String,
      text: json['text'] as String,
      textSecondary: json['textSecondary'] as String,
    );
  }
}

/// 브랜드 폰트
class BrandFonts {
  final String heading;
  final String body;
  final String caption;

  const BrandFonts({
    required this.heading,
    required this.body,
    required this.caption,
  });

  factory BrandFonts.defaultFonts() {
    return const BrandFonts(heading: 'Inter', body: 'Inter', caption: 'Inter');
  }

  Map<String, dynamic> toJson() {
    return {'heading': heading, 'body': body, 'caption': caption};
  }

  factory BrandFonts.fromJson(Map<String, dynamic> json) {
    return BrandFonts(
      heading: json['heading'] as String,
      body: json['body'] as String,
      caption: json['caption'] as String,
    );
  }
}
