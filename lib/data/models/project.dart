import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import 'slide.dart';
import 'avatar.dart';
import 'script.dart';
import 'asset.dart';
import 'brand_kit.dart';

/// 강의 프로젝트 모델
class LectureProject {
  final String id;
  final String title;
  final String description;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 프로젝트 구성 요소
  final Script script;
  final List<SlideData> slides;
  final Avatar? avatar;
  final BrandKit? brandKit;
  final ProjectSettings settings;
  
  // 메타데이터
  final List<String> tags;
  final String? thumbnailPath;
  final int version;
  final Map<String, dynamic> metadata;

  const LectureProject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.script,
    required this.slides,
    this.avatar,
    this.brandKit,
    required this.settings,
    this.tags = const [],
    this.thumbnailPath,
    this.version = 1,
    this.metadata = const {},
  });

  /// 새 프로젝트 생성
  factory LectureProject.create({
    required String title,
    required String description,
    String? scriptContent,
    Map<String, dynamic>? extraMetadata,
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    
    final defaultMetadata = {
      'creator': 'EidosStudio',
      'platform': 'web',
      'created_with_version': AppConstants.appVersion,
    };

    return LectureProject(
      id: id,
      title: title,
      description: description,
      status: ProjectStatus.draft,
      createdAt: now,
      updatedAt: now,
      script: Script.create(content: scriptContent ?? ''),
      slides: [],
      settings: ProjectSettings.defaultSettings(),
      tags: [],
      version: 1,
      metadata: {
        ...defaultMetadata,
        if (scriptContent != null) 'initial_script': scriptContent,
        if (extraMetadata != null) ...extraMetadata,
      },
    );
  }

  /// 프로젝트 복사
  LectureProject copyWith({
    String? title,
    String? description,
    ProjectStatus? status,
    DateTime? updatedAt,
    Script? script,
    List<SlideData>? slides,
    Avatar? avatar,
    BrandKit? brandKit,
    ProjectSettings? settings,
    List<String>? tags,
    String? thumbnailPath,
    int? version,
    Map<String, dynamic>? metadata,
  }) {
    return LectureProject(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      script: script ?? this.script,
      slides: slides ?? this.slides,
      avatar: avatar ?? this.avatar,
      brandKit: brandKit ?? this.brandKit,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'script': script.toJson(),
      'slides': slides.map((slide) => slide.toJson()).toList(),
      'avatar': avatar?.toJson(),
      'brandKit': brandKit?.toJson(),
      'settings': settings.toJson(),
      'tags': tags,
      'thumbnailPath': thumbnailPath,
      'version': version,
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory LectureProject.fromJson(Map<String, dynamic> json) {
    return LectureProject(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: ProjectStatus.values.firstWhere(
        (status) => status.id == json['status'],
        orElse: () => ProjectStatus.draft,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      script: json['script'] != null 
          ? Script.fromJson(json['script'] as Map<String, dynamic>)
          : Script.empty(),
      slides: (json['slides'] as List? ?? [])
          .map((slide) => SlideData.fromJson(slide as Map<String, dynamic>))
          .toList(),
      avatar: json['avatar'] != null 
          ? Avatar.fromJson(json['avatar'] as Map<String, dynamic>)
          : null,
      brandKit: json['brandKit'] != null
          ? BrandKit.fromJson(json['brandKit'] as Map<String, dynamic>)
          : null,
      settings: ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailPath: json['thumbnailPath'] as String?,
      version: json['version'] as int? ?? 1,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 프로젝트 통계
  ProjectStats get stats {
    return ProjectStats(
      totalSlides: slides.length,
      totalDuration: slides.fold(
        Duration.zero,
        (duration, slide) => duration + slide.duration,
      ),
      completedSlides: slides.where((slide) => slide.isCompleted).length,
      scriptWordCount: script.wordCount,
      hasAvatar: avatar != null,
      lastModified: updatedAt,
    );
  }

  /// 프로젝트 검증
  ProjectValidation validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // 필수 요소 검증
    if (title.trim().isEmpty) {
      errors.add('프로젝트 제목이 필요합니다');
    }
    
    if (script.content.trim().isEmpty) {
      warnings.add('스크립트 내용이 비어있습니다');
    }
    
    if (slides.isEmpty) {
      warnings.add('슬라이드가 없습니다');
    }
    
    // 슬라이드 검증
    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      if (slide.title.trim().isEmpty) {
        warnings.add('슬라이드 ${i + 1}의 제목이 비어있습니다');
      }
      if (slide.elements.isEmpty) {
        warnings.add('슬라이드 ${i + 1}에 콘텐츠가 없습니다');
      }
    }

    return ProjectValidation(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// 프로젝트 설정
class ProjectSettings {
  final TemplateCategory templateCategory;
  final SupportedLanguage language;
  final bool autoGenerateSubtitles;
  final bool includeChapterMarkers;
  final VideoQuality videoQuality;
  final AudioQuality audioQuality;
  final ExportSettings exportSettings;

  const ProjectSettings({
    required this.templateCategory,
    required this.language,
    this.autoGenerateSubtitles = true,
    this.includeChapterMarkers = true,
    this.videoQuality = VideoQuality.high,
    this.audioQuality = AudioQuality.standard,
    required this.exportSettings,
  });

  factory ProjectSettings.defaultSettings() {
    return ProjectSettings(
      templateCategory: TemplateCategory.presentation,
      language: SupportedLanguage.korean,
      exportSettings: ExportSettings.defaultSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateCategory': templateCategory.id,
      'language': language.code,
      'autoGenerateSubtitles': autoGenerateSubtitles,
      'includeChapterMarkers': includeChapterMarkers,
      'videoQuality': videoQuality.name,
      'audioQuality': audioQuality.name,
      'exportSettings': exportSettings.toJson(),
    };
  }

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      templateCategory: TemplateCategory.values.firstWhere(
        (cat) => cat.id == json['templateCategory'],
        orElse: () => TemplateCategory.presentation,
      ),
      language: SupportedLanguage.values.firstWhere(
        (lang) => lang.code == json['language'],
        orElse: () => SupportedLanguage.korean,
      ),
      autoGenerateSubtitles: json['autoGenerateSubtitles'] as bool? ?? true,
      includeChapterMarkers: json['includeChapterMarkers'] as bool? ?? true,
      videoQuality: VideoQuality.values.firstWhere(
        (quality) => quality.name == json['videoQuality'],
        orElse: () => VideoQuality.high,
      ),
      audioQuality: AudioQuality.values.firstWhere(
        (quality) => quality.name == json['audioQuality'],
        orElse: () => AudioQuality.standard,
      ),
      exportSettings: ExportSettings.fromJson(
        json['exportSettings'] as Map<String, dynamic>,
      ),
    );
  }
}

/// 내보내기 설정
class ExportSettings {
  final List<ExportFormat> formats;
  final int videoBitrate;
  final int audioBitrate;
  final double frameRate;
  final bool includeWatermark;

  const ExportSettings({
    required this.formats,
    this.videoBitrate = AppConstants.defaultVideoBitrate,
    this.audioBitrate = AppConstants.defaultAudioBitrate,
    this.frameRate = 30.0,
    this.includeWatermark = false,
  });

  factory ExportSettings.defaultSettings() {
    return const ExportSettings(
      formats: [ExportFormat.mp4, ExportFormat.pdf],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formats': formats.map((f) => f.name).toList(),
      'videoBitrate': videoBitrate,
      'audioBitrate': audioBitrate,
      'frameRate': frameRate,
      'includeWatermark': includeWatermark,
    };
  }

  factory ExportSettings.fromJson(Map<String, dynamic> json) {
    return ExportSettings(
      formats: (json['formats'] as List<dynamic>)
          .map((name) => ExportFormat.values.firstWhere(
                (format) => format.name == name,
                orElse: () => ExportFormat.mp4,
              ))
          .toList(),
      videoBitrate: json['videoBitrate'] as int? ?? AppConstants.defaultVideoBitrate,
      audioBitrate: json['audioBitrate'] as int? ?? AppConstants.defaultAudioBitrate,
      frameRate: (json['frameRate'] as num?)?.toDouble() ?? 30.0,
      includeWatermark: json['includeWatermark'] as bool? ?? false,
    );
  }
}

/// 프로젝트 통계
class ProjectStats {
  final int totalSlides;
  final Duration totalDuration;
  final int completedSlides;
  final int scriptWordCount;
  final bool hasAvatar;
  final DateTime lastModified;

  const ProjectStats({
    required this.totalSlides,
    required this.totalDuration,
    required this.completedSlides,
    required this.scriptWordCount,
    required this.hasAvatar,
    required this.lastModified,
  });

  double get completionPercentage {
    if (totalSlides == 0) return 0.0;
    return completedSlides / totalSlides;
  }

  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// 프로젝트 검증 결과
class ProjectValidation {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ProjectValidation({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// 영상 품질
enum VideoQuality {
  low(720, 1280),
  standard(1080, 1920),
  high(1440, 2560),
  ultra(2160, 3840);

  const VideoQuality(this.height, this.width);
  final int height;
  final int width;
}

/// 오디오 품질
enum AudioQuality {
  low(96000),
  standard(128000),
  high(192000),
  ultra(320000);

  const AudioQuality(this.bitrate);
  final int bitrate;
}

/// 내보내기 형식
enum ExportFormat {
  mp4,
  pptx,
  pdf,
  png;
}


