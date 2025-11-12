import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../utils/json_date_parser.dart';

/// 아바타 모델 (HeyGen 기반)
class Avatar {
  final String id;
  final String name;
  final String? imagePath; // 업로드된 얼굴 사진 경로
  final String? heygenAvatarId; // HeyGen에서 생성된 아바타 ID
  final AvatarGender gender;
  final VoiceSettings voiceSettings;
  final AvatarStyle style;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AvatarStatus status;
  final Map<String, dynamic> metadata;

  const Avatar({
    required this.id,
    required this.name,
    this.imagePath,
    this.heygenAvatarId,
    required this.gender,
    required this.voiceSettings,
    required this.style,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.metadata = const {},
  });

  /// 새 아바타 생성
  factory Avatar.create({
    required String name,
    required String imagePath,
    AvatarGender gender = AvatarGender.neutral,
  }) {
    final now = DateTime.now();
    return Avatar(
      id: const Uuid().v4(),
      name: name,
      imagePath: imagePath,
      gender: gender,
      voiceSettings: VoiceSettings.defaultSettings(),
      style: AvatarStyle.professional,
      createdAt: now,
      updatedAt: now,
      status: AvatarStatus.pending,
    );
  }

  /// 아바타 복사
  Avatar copyWith({
    String? name,
    String? imagePath,
    String? heygenAvatarId,
    AvatarGender? gender,
    VoiceSettings? voiceSettings,
    AvatarStyle? style,
    DateTime? updatedAt,
    AvatarStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Avatar(
      id: id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      heygenAvatarId: heygenAvatarId ?? this.heygenAvatarId,
      gender: gender ?? this.gender,
      voiceSettings: voiceSettings ?? this.voiceSettings,
      style: style ?? this.style,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'heygenAvatarId': heygenAvatarId,
      'gender': gender.name,
      'voiceSettings': voiceSettings.toJson(),
      'style': style.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String?,
      heygenAvatarId: json['heygenAvatarId'] as String?,
      gender: AvatarGender.values.firstWhere(
        (gender) => gender.name == json['gender'],
        orElse: () => AvatarGender.neutral,
      ),
      voiceSettings: VoiceSettings.fromJson(
        json['voiceSettings'] as Map<String, dynamic>,
      ),
      style: AvatarStyle.values.firstWhere(
        (style) => style.name == json['style'],
        orElse: () => AvatarStyle.professional,
      ),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      status: AvatarStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AvatarStatus.pending,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 아바타 사용 가능 여부
  bool get isReady => status == AvatarStatus.ready;

  /// 아바타 생성 중 여부
  bool get isGenerating => status == AvatarStatus.generating;

  /// 오류 상태 여부
  bool get hasError => status == AvatarStatus.error;
}

/// 음성 설정
class VoiceSettings {
  final VoiceType type;
  final String? voiceId; // HeyGen 음성 ID
  final SupportedLanguage language;
  final double speed; // 0.5 ~ 2.0
  final double pitch; // 0.5 ~ 2.0
  final double volume; // 0.0 ~ 1.0
  final bool enableEmotions;
  final Map<String, dynamic> customSettings;

  const VoiceSettings({
    required this.type,
    this.voiceId,
    required this.language,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.volume = 0.8,
    this.enableEmotions = true,
    this.customSettings = const {},
  });

  /// 기본 음성 설정
  factory VoiceSettings.defaultSettings() {
    return const VoiceSettings(
      type: VoiceType.basic,
      language: SupportedLanguage.korean,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'voiceId': voiceId,
      'language': language.code,
      'speed': speed,
      'pitch': pitch,
      'volume': volume,
      'enableEmotions': enableEmotions,
      'customSettings': customSettings,
    };
  }

  /// JSON에서 생성
  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      type: VoiceType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => VoiceType.basic,
      ),
      voiceId: json['voiceId'] as String?,
      language: SupportedLanguage.values.firstWhere(
        (lang) => lang.code == json['language'],
        orElse: () => SupportedLanguage.korean,
      ),
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      enableEmotions: json['enableEmotions'] as bool? ?? true,
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }

  /// 음성 설정 복사
  VoiceSettings copyWith({
    VoiceType? type,
    String? voiceId,
    SupportedLanguage? language,
    double? speed,
    double? pitch,
    double? volume,
    bool? enableEmotions,
    Map<String, dynamic>? customSettings,
  }) {
    return VoiceSettings(
      type: type ?? this.type,
      voiceId: voiceId ?? this.voiceId,
      language: language ?? this.language,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      enableEmotions: enableEmotions ?? this.enableEmotions,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// 아바타 비디오 클립
class AvatarVideoClip {
  final String id;
  final String avatarId;
  final String scriptText;
  final String? videoUrl; // HeyGen에서 생성된 비디오 URL
  final Duration duration;
  final VideoClipStatus status;
  final DateTime createdAt;
  final String? subtitlesPath; // SRT 파일 경로
  final Map<String, dynamic> metadata;

  const AvatarVideoClip({
    required this.id,
    required this.avatarId,
    required this.scriptText,
    this.videoUrl,
    required this.duration,
    required this.status,
    required this.createdAt,
    this.subtitlesPath,
    this.metadata = const {},
  });

  /// 새 비디오 클립 생성
  factory AvatarVideoClip.create({
    required String avatarId,
    required String scriptText,
  }) {
    return AvatarVideoClip(
      id: const Uuid().v4(),
      avatarId: avatarId,
      scriptText: scriptText,
      duration: Duration.zero,
      status: VideoClipStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatarId': avatarId,
      'scriptText': scriptText,
      'videoUrl': videoUrl,
      'duration': duration.inSeconds,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'subtitlesPath': subtitlesPath,
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory AvatarVideoClip.fromJson(Map<String, dynamic> json) {
    return AvatarVideoClip(
      id: json['id'] as String,
      avatarId: json['avatarId'] as String,
      scriptText: json['scriptText'] as String,
      videoUrl: json['videoUrl'] as String?,
      duration: Duration(seconds: json['duration'] as int),
      status: VideoClipStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => VideoClipStatus.pending,
      ),
      createdAt: parseDateTime(json['createdAt']),
      subtitlesPath: json['subtitlesPath'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 비디오 클립 복사
  AvatarVideoClip copyWith({
    String? scriptText,
    String? videoUrl,
    Duration? duration,
    VideoClipStatus? status,
    String? subtitlesPath,
    Map<String, dynamic>? metadata,
  }) {
    return AvatarVideoClip(
      id: id,
      avatarId: avatarId,
      scriptText: scriptText ?? this.scriptText,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: createdAt,
      subtitlesPath: subtitlesPath ?? this.subtitlesPath,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 준비 완료 여부
  bool get isReady => status == VideoClipStatus.ready && videoUrl != null;

  /// 생성 중 여부
  bool get isGenerating => status == VideoClipStatus.generating;

  /// 오류 상태 여부
  bool get hasError => status == VideoClipStatus.error;
}

/// 아바타 성별
enum AvatarGender {
  male('남성'),
  female('여성'),
  neutral('중성');

  const AvatarGender(this.displayName);
  final String displayName;
}

/// 아바타 스타일
enum AvatarStyle {
  professional('전문적'),
  casual('캐주얼'),
  friendly('친근한'),
  authoritative('권위적');

  const AvatarStyle(this.displayName);
  final String displayName;
}

/// 아바타 상태
enum AvatarStatus {
  pending('대기중'),
  generating('생성중'),
  ready('준비완료'),
  error('오류');

  const AvatarStatus(this.displayName);
  final String displayName;
}

/// 음성 타입
enum VoiceType {
  basic('기본 음성'),
  cloned('클론 음성'),
  external('외부 TTS');

  const VoiceType(this.displayName);
  final String displayName;
}

/// 비디오 클립 상태
enum VideoClipStatus {
  pending('대기중'),
  generating('생성중'),
  ready('준비완료'),
  error('오류');

  const VideoClipStatus(this.displayName);
  final String displayName;
}
