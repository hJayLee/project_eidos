enum VideoStatus {
  pending,
  processing,
  completed,
  failed,
}

enum AvatarType {
  photo,
  aiGenerated,
  custom,
}

class Avatar {
  final String id;
  final AvatarType type;
  final String imageUrl;
  final Map<String, dynamic> settings;
  final DateTime createdAt;

  Avatar({
    required this.id,
    required this.type,
    required this.imageUrl,
    this.settings = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Avatar copyWith({
    String? id,
    AvatarType? type,
    String? imageUrl,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
  }) {
    return Avatar(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'imageUrl': imageUrl,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      type: AvatarType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      imageUrl: json['imageUrl'],
      settings: json['settings'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Video {
  final String id;
  final String slideId;
  final Avatar avatar;
  final String script;
  final Duration duration;
  final VideoStatus status;
  final String? videoUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Video({
    required this.id,
    required this.slideId,
    required this.avatar,
    required this.script,
    this.duration = Duration.zero,
    this.status = VideoStatus.pending,
    this.videoUrl,
    this.thumbnailUrl,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Video copyWith({
    String? id,
    String? slideId,
    Avatar? avatar,
    String? script,
    Duration? duration,
    VideoStatus? status,
    String? videoUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Video(
      id: id ?? this.id,
      slideId: slideId ?? this.slideId,
      avatar: avatar ?? this.avatar,
      script: script ?? this.script,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slideId': slideId,
      'avatar': avatar.toJson(),
      'script': script,
      'duration': duration.inMilliseconds,
      'status': status.name,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'],
      slideId: json['slideId'],
      avatar: Avatar.fromJson(json['avatar']),
      script: json['script'],
      duration: Duration(milliseconds: json['duration']),
      status: VideoStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
