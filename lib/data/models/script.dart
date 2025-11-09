import 'package:uuid/uuid.dart';

/// 강의 스크립트 모델
class Script {
  final String id;
  final String content;
  final List<ScriptChapter> chapters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const Script({
    required this.id,
    required this.content,
    required this.chapters,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// 새 스크립트 생성
  factory Script.create({
    required String content,
  }) {
    final now = DateTime.now();
    return Script(
      id: const Uuid().v4(),
      content: content,
      chapters: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 빈 스크립트 생성
  factory Script.empty() {
    final now = DateTime.now();
    return Script(
      id: const Uuid().v4(),
      content: '',
      chapters: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 스크립트 복사
  Script copyWith({
    String? content,
    List<ScriptChapter>? chapters,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Script(
      id: id,
      content: content ?? this.content,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory Script.fromJson(Map<String, dynamic> json) {
    return Script(
      id: json['id'] as String,
      content: json['content'] as String,
      chapters: (json['chapters'] as List?)
              ?.map((chapter) => ScriptChapter.fromJson(chapter as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 단어 수 계산
  int get wordCount {
    return content.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// 예상 읽기 시간 (분)
  double get estimatedReadingTime {
    // 평균 읽기 속도: 분당 150단어
    return wordCount / 150.0;
  }

  /// 챕터 자동 생성
  List<ScriptChapter> generateChapters() {
    final chapters = <ScriptChapter>[];
    final lines = content.split('\n');
    
    String currentChapterTitle = '';
    String currentChapterContent = '';
    int chapterIndex = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // 챕터 제목 감지 (## 또는 # 으로 시작하는 라인)
      if (trimmedLine.startsWith('##') || trimmedLine.startsWith('#')) {
        // 이전 챕터 저장
        if (currentChapterTitle.isNotEmpty && currentChapterContent.isNotEmpty) {
          chapters.add(ScriptChapter(
            id: const Uuid().v4(),
            title: currentChapterTitle,
            content: currentChapterContent.trim(),
            order: chapterIndex,
            startTime: _calculateStartTime(chapterIndex),
            duration: _estimateChapterDuration(currentChapterContent),
          ));
          chapterIndex++;
        }
        
        // 새 챕터 시작
        currentChapterTitle = trimmedLine.replaceFirst(RegExp(r'^#{1,2}\s*'), '');
        currentChapterContent = '';
      } else if (trimmedLine.isNotEmpty) {
        currentChapterContent += '$line\n';
      }
    }
    
    // 마지막 챕터 저장
    if (currentChapterTitle.isNotEmpty && currentChapterContent.isNotEmpty) {
      chapters.add(ScriptChapter(
        id: const Uuid().v4(),
        title: currentChapterTitle,
        content: currentChapterContent.trim(),
        order: chapterIndex,
        startTime: _calculateStartTime(chapterIndex),
        duration: _estimateChapterDuration(currentChapterContent),
      ));
    }
    
    // 챕터가 없으면 전체를 하나의 챕터로 처리
    if (chapters.isEmpty && content.trim().isNotEmpty) {
      chapters.add(ScriptChapter(
        id: const Uuid().v4(),
        title: '메인 콘텐츠',
        content: content.trim(),
        order: 0,
        startTime: Duration.zero,
        duration: _estimateChapterDuration(content),
      ));
    }
    
    return chapters;
  }

  /// 챕터 시작 시간 계산
  Duration _calculateStartTime(int chapterIndex) {
    if (chapterIndex == 0) return Duration.zero;
    
    double totalMinutes = 0;
    for (int i = 0; i < chapterIndex; i++) {
      if (i < chapters.length) {
        totalMinutes += chapters[i].duration.inSeconds / 60.0;
      }
    }
    return Duration(seconds: (totalMinutes * 60).round());
  }

  /// 챕터 길이 추정
  Duration _estimateChapterDuration(String content) {
    final words = content.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    // 평균 읽기 속도: 분당 150단어
    final minutes = words / 150.0;
    return Duration(seconds: (minutes * 60).round());
  }

  /// 키워드 추출
  List<String> extractKeywords() {
    final words = content.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s가-힣]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();
    
    // 단어 빈도 계산
    final wordFrequency = <String, int>{};
    for (final word in words) {
      wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
    }
    
    // 빈도 순으로 정렬하여 상위 10개 반환
    final sortedWords = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.take(10).map((entry) => entry.key).toList();
  }
}

/// 스크립트 챕터
class ScriptChapter {
  final String id;
  final String title;
  final String content;
  final int order;
  final Duration startTime;
  final Duration duration;
  final Map<String, dynamic> metadata;

  const ScriptChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.startTime,
    required this.duration,
    this.metadata = const {},
  });

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'startTime': startTime.inSeconds,
      'duration': duration.inSeconds,
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory ScriptChapter.fromJson(Map<String, dynamic> json) {
    return ScriptChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
      startTime: Duration(seconds: json['startTime'] as int),
      duration: Duration(seconds: json['duration'] as int),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 종료 시간
  Duration get endTime => startTime + duration;

  /// 타임코드 형식 (hh:mm:ss)
  String get formattedStartTime {
    final hours = startTime.inHours;
    final minutes = startTime.inMinutes % 60;
    final seconds = startTime.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    final hours = endTime.inHours;
    final minutes = endTime.inMinutes % 60;
    final seconds = endTime.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 타임코드 범위
  String get timeRange => '$formattedStartTime - $formattedEndTime';

  /// 단어 수
  int get wordCount {
    return content.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// 챕터 복사
  ScriptChapter copyWith({
    String? title,
    String? content,
    int? order,
    Duration? startTime,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    return ScriptChapter(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }
}


