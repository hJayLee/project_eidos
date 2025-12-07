import 'package:cloud_firestore/cloud_firestore.dart';

/// 아바타 영상 생성 작업
class AvatarJob {
  final String jobId;
  final String userId;
  final String instructorName;
  final String instructorBio;
  
  final AvatarJobStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  
  final AvatarJobProgress progress;
  
  final String? videoUrl;
  final String? errorMessage;

  AvatarJob({
    required this.jobId,
    required this.userId,
    required this.instructorName,
    required this.instructorBio,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    required this.progress,
    this.videoUrl,
    this.errorMessage,
  });

  factory AvatarJob.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AvatarJob(
      jobId: doc.id,
      userId: data['userId'] ?? '',
      instructorName: data['instructorName'] ?? '',
      instructorBio: data['instructorBio'] ?? '',
      status: AvatarJobStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AvatarJobStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      progress: AvatarJobProgress.fromMap(data['progress'] ?? {}),
      videoUrl: data['videoUrl'],
      errorMessage: data['errorMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'instructorName': instructorName,
      'instructorBio': instructorBio,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'progress': progress.toMap(),
      'videoUrl': videoUrl,
      'errorMessage': errorMessage,
    };
  }
}

/// 작업 상태
enum AvatarJobStatus {
  pending,      // 대기중
  processing,   // 처리중
  completed,    // 완료
  failed,       // 실패
}

/// 작업 진행 상황
class AvatarJobProgress {
  final String currentStep;
  final int stepNumber;
  final int totalSteps;
  final String? message;

  AvatarJobProgress({
    required this.currentStep,
    required this.stepNumber,
    required this.totalSteps,
    this.message,
  });

  factory AvatarJobProgress.fromMap(Map<String, dynamic> map) {
    return AvatarJobProgress(
      currentStep: map['currentStep'] ?? 'pending',
      stepNumber: map['stepNumber'] ?? 0,
      totalSteps: map['totalSteps'] ?? 3,
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStep': currentStep,
      'stepNumber': stepNumber,
      'totalSteps': totalSteps,
      'message': message,
    };
  }

  int get percentage {
    if (totalSteps == 0) return 0;
    return ((stepNumber / totalSteps) * 100).round();
  }

  String get displayText {
    switch (currentStep) {
      case 'avatar_creation':
        return '아바타 생성 중...';
      case 'voice_cloning':
        return '음성 클론 중...';
      case 'video_generation':
        return '영상 생성 중...';
      case 'completed':
        return '완료';
      default:
        return message ?? '대기중';
    }
  }
}

