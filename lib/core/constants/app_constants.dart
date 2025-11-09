import 'package:flutter/material.dart';

/// 앱 전역 상수 정의
class AppConstants {
  // 색상 상수
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color textPrimaryColor = Color(0xFFF8FAFC);
  static const Color textSecondaryColor = Color(0xFF94A3B8);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  
  // 텍스트 스타일
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );
  
  // 간격 상수
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // 반지름 상수
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  
  // 그림자 상수
  static const List<BoxShadow> shadowS = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowM = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowL = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  // 애니메이션 지속시간
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // API 관련 상수
  static const String openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String skyworkApiUrl = 'https://api.skywork.ai/v1';
  static const String heygenApiUrl = 'https://api.heygen.com/v1';
  
  // 앱 정보
  static const String appName = 'Project Eidos';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered presentation creation tool';
  
  // 비디오 설정
  static const int defaultVideoBitrate = 5000;
  static const int defaultAudioBitrate = 128;
}

/// 미디어 타입 열거형
enum MediaType {
  image,
  video,
  audio,
  document,
}

/// 프로젝트 상태 열거형
enum ProjectStatus {
  draft,
  editing,
  generating,
  processing,
  completed,
  failed,
  error,
  published,
}

/// 템플릿 카테고리 열거형
enum TemplateCategory {
  business,
  education,
  marketing,
  technology,
  creative,
  presentation,
  ai_video_editing,
  business_automation,
}

/// 지원 언어 열거형
enum SupportedLanguage {
  korean,
  english,
  japanese,
  chinese,
  spanish,
  french,
  german,
}

/// 슬라이드 요소 타입 열거형
enum SlideElementType {
  text,
  image,
  video,
  chart,
  table,
  shape,
  icon,
  background,
  animation,
}

/// MediaType 확장
extension MediaTypeExtension on MediaType {
  int get id => index;
  String get displayName {
    switch (this) {
      case MediaType.image:
        return '이미지';
      case MediaType.video:
        return '비디오';
      case MediaType.audio:
        return '오디오';
      case MediaType.document:
        return '문서';
    }
  }
}

/// ProjectStatus 확장
extension ProjectStatusExtension on ProjectStatus {
  int get id => index;
  String get displayName {
    switch (this) {
      case ProjectStatus.draft:
        return '초안';
      case ProjectStatus.editing:
        return '편집 중';
      case ProjectStatus.generating:
        return '생성 중';
      case ProjectStatus.processing:
        return '처리 중';
      case ProjectStatus.completed:
        return '완료';
      case ProjectStatus.failed:
        return '실패';
      case ProjectStatus.error:
        return '오류';
      case ProjectStatus.published:
        return '발행됨';
    }
  }
}

/// TemplateCategory 확장
extension TemplateCategoryExtension on TemplateCategory {
  int get id => index;
  String get displayName {
    switch (this) {
      case TemplateCategory.business:
        return '비즈니스';
      case TemplateCategory.education:
        return '교육';
      case TemplateCategory.marketing:
        return '마케팅';
      case TemplateCategory.technology:
        return '기술';
      case TemplateCategory.creative:
        return '크리에이티브';
      case TemplateCategory.presentation:
        return '프레젠테이션';
      case TemplateCategory.ai_video_editing:
        return 'AI 비디오 편집';
      case TemplateCategory.business_automation:
        return '비즈니스 자동화';
    }
  }
}

/// SupportedLanguage 확장
extension SupportedLanguageExtension on SupportedLanguage {
  String get code {
    switch (this) {
      case SupportedLanguage.korean:
        return 'ko';
      case SupportedLanguage.english:
        return 'en';
      case SupportedLanguage.japanese:
        return 'ja';
      case SupportedLanguage.chinese:
        return 'zh';
      case SupportedLanguage.spanish:
        return 'es';
      case SupportedLanguage.french:
        return 'fr';
      case SupportedLanguage.german:
        return 'de';
    }
  }
  String get displayName {
    switch (this) {
      case SupportedLanguage.korean:
        return '한국어';
      case SupportedLanguage.english:
        return 'English';
      case SupportedLanguage.japanese:
        return '日本語';
      case SupportedLanguage.chinese:
        return '中文';
      case SupportedLanguage.spanish:
        return 'Español';
      case SupportedLanguage.french:
        return 'Français';
      case SupportedLanguage.german:
        return 'Deutsch';
    }
  }
}

/// SlideElementType 확장
extension SlideElementTypeExtension on SlideElementType {
  String get displayName {
    switch (this) {
      case SlideElementType.text:
        return '텍스트';
      case SlideElementType.image:
        return '이미지';
      case SlideElementType.video:
        return '비디오';
      case SlideElementType.chart:
        return '차트';
      case SlideElementType.table:
        return '표';
      case SlideElementType.shape:
        return '도형';
      case SlideElementType.icon:
        return '아이콘';
      case SlideElementType.background:
        return '배경';
      case SlideElementType.animation:
        return '애니메이션';
    }
  }
}