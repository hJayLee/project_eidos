import 'dart:ui';
import '../models/design_template.dart';

  /// 기본 디자인 템플릿 데이터
  class TemplateData {
    static List<DesignTemplate> get defaultTemplates => [
      modernBusiness,
      creativeInnovation,
      minimalClean,
      academicResearch,
      modernTech,
    ];

    /// Modern Business 템플릿
    static DesignTemplate get modernBusiness => DesignTemplate(
    id: 'modern_business',
    name: 'Modern Business',
    category: 'business',
    description: '전문적이고 신뢰감 있는 비즈니스 프레젠테이션',
    previewImage: 'assets/images/templates/modern_business_preview.png',
    tags: ['비즈니스', '전문적', '신뢰감', '깔끔함'],
    layouts: [
      SlideLayout(
        id: 'title_content',
        name: '제목 + 내용',
        description: '제목과 주요 내용을 강조하는 레이아웃',
        placeholders: [
          ElementPlaceholder(
            id: 'title',
            type: 'title',
            position: Offset(100, 80),
            size: Size(600, 80),
            properties: {'maxLength': 50, 'style': 'large_bold'},
          ),
          ElementPlaceholder(
            id: 'content',
            type: 'content',
            position: Offset(100, 200),
            size: Size(600, 300),
            properties: {'maxLength': 200, 'style': 'body'},
          ),
          ElementPlaceholder(
            id: 'accent_icon',
            type: 'icon',
            position: Offset(720, 100),
            size: Size(80, 80),
            properties: {'icon': '💼', 'style': 'accent'},
          ),
        ],
        colorScheme: ColorScheme(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF1976D2),
          accent: Color(0xFFFF9800),
          background: Color(0xFFF5F5F5),
          surface: Color(0xFFFFFFFF),
          text: Color(0xFF212121),
          textSecondary: Color(0xFF757575),
        ),
        typography: Typography(
          titleFontFamily: 'Roboto',
          bodyFontFamily: 'Roboto',
          titleFontSize: 36.0,
          bodyFontSize: 18.0,
          titleFontWeight: FontWeight.bold,
          bodyFontWeight: FontWeight.normal,
        ),
        background: BackgroundStyle(
          type: 'gradient',
          gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          opacity: 0.8,
        ),
      ),
    ],
    designRules: {
      'spacing': 'generous',
      'alignment': 'left',
      'emphasis': 'title',
      'visual_hierarchy': 'clear',
    },
  );

      /// Creative Innovation 템플릿
    static DesignTemplate get creativeInnovation => DesignTemplate(
    id: 'creative_innovation',
    name: 'Creative Innovation',
    category: 'creative',
    description: '창의적이고 혁신적인 아이디어를 표현하는 템플릿',
    previewImage: 'assets/images/templates/creative_innovation_preview.png',
    tags: ['창의적', '혁신', '아이디어', '색채'],
    layouts: [
      SlideLayout(
        id: 'centered_focus',
        name: '중앙 집중형',
        description: '중앙에 핵심 아이디어를 배치하는 레이아웃',
        placeholders: [
          ElementPlaceholder(
            id: 'main_icon',
            type: 'icon',
            position: Offset(350, 150),
            size: Size(120, 120),
            properties: {'icon': '🚀', 'style': 'large_accent'},
          ),
          ElementPlaceholder(
            id: 'title',
            type: 'title',
            position: Offset(200, 300),
            size: Size(400, 60),
            properties: {'maxLength': 40, 'style': 'creative_bold'},
          ),
          ElementPlaceholder(
            id: 'supporting_points',
            type: 'bullet_list',
            position: Offset(150, 400),
            size: Size(500, 150),
            properties: {'maxItems': 3, 'style': 'creative'},
          ),
        ],
        colorScheme: ColorScheme(
          primary: Color(0xFF9C27B0),
          secondary: Color(0xFF7B1FA2),
          accent: Color(0xFFFF9800),
          background: Color(0xFFF3E5F5),
          surface: Color(0xFFFFFFFF),
          text: Color(0xFF4A148C),
          textSecondary: Color(0xFF7B1FA2),
        ),
        typography: Typography(
          titleFontFamily: 'Poppins',
          bodyFontFamily: 'Poppins',
          titleFontSize: 32.0,
          bodyFontSize: 16.0,
          titleFontWeight: FontWeight.w600,
          bodyFontWeight: FontWeight.normal,
        ),
        background: BackgroundStyle(
          type: 'gradient',
          gradientColors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
          opacity: 0.6,
        ),
      ),
    ],
    designRules: {
      'spacing': 'balanced',
      'alignment': 'center',
      'emphasis': 'visual',
      'visual_hierarchy': 'creative',
    },
  );

      /// Minimal Clean 템플릿
    static DesignTemplate get minimalClean => DesignTemplate(
    id: 'minimal_clean',
    name: 'Minimal Clean',
    category: 'minimal',
    description: '깔끔하고 심플한 미니멀 디자인',
    previewImage: 'assets/images/templates/minimal_clean_preview.png',
    tags: ['미니멀', '깔끔함', '심플', '우아함'],
    layouts: [
      SlideLayout(
        id: 'simple_layout',
        name: '심플 레이아웃',
        description: '최소한의 요소로 구성된 깔끔한 레이아웃',
        placeholders: [
          ElementPlaceholder(
            id: 'title',
            type: 'title',
            position: Offset(80, 100),
            size: Size(640, 60),
            properties: {'maxLength': 60, 'style': 'minimal'},
          ),
          ElementPlaceholder(
            id: 'content',
            type: 'content',
            position: Offset(80, 200),
            size: Size(640, 200),
            properties: {'maxLength': 150, 'style': 'minimal_body'},
          ),
          ElementPlaceholder(
            id: 'accent_line',
            type: 'decoration',
            position: Offset(80, 180),
            size: Size(100, 2),
            properties: {'style': 'accent_line', 'color': 'accent'},
          ),
        ],
        colorScheme: ColorScheme(
          primary: Color(0xFF424242),
          secondary: Color(0xFF757575),
          accent: Color(0xFF9E9E9E),
          background: Color(0xFFFFFFFF),
          surface: Color(0xFFFAFAFA),
          text: Color(0xFF212121),
          textSecondary: Color(0xFF757575),
        ),
        typography: Typography(
          titleFontFamily: 'Inter',
          bodyFontFamily: 'Inter',
          titleFontSize: 28.0,
          bodyFontSize: 16.0,
          titleFontWeight: FontWeight.w500,
          bodyFontWeight: FontWeight.normal,
        ),
        background: BackgroundStyle(
          type: 'solid',
          solidColor: Color(0xFFFFFFFF),
        ),
      ),
    ],
    designRules: {
      'spacing': 'minimal',
      'alignment': 'left',
      'emphasis': 'content',
      'visual_hierarchy': 'subtle',
    },
  );

      /// Academic Research 템플릿
    static DesignTemplate get academicResearch => DesignTemplate(
    id: 'academic_research',
    name: 'Academic Research',
    category: 'academic',
    description: '학술적이고 체계적인 연구 프레젠테이션',
    previewImage: 'assets/images/templates/academic_research_preview.png',
    tags: ['학술', '연구', '체계적', '전문적'],
    layouts: [
      SlideLayout(
        id: 'research_layout',
        name: '연구 레이아웃',
        description: '연구 내용을 체계적으로 정리하는 레이아웃',
        placeholders: [
          ElementPlaceholder(
            id: 'title',
            type: 'title',
            position: Offset(80, 60),
            size: Size(640, 50),
            properties: {'maxLength': 70, 'style': 'academic_title'},
          ),
          ElementPlaceholder(
            id: 'author_info',
            type: 'content',
            position: Offset(80, 120),
            size: Size(300, 40),
            properties: {'maxLength': 50, 'style': 'author'},
          ),
          ElementPlaceholder(
            id: 'main_content',
            type: 'content',
            position: Offset(80, 180),
            size: Size(640, 250),
            properties: {'maxLength': 300, 'style': 'academic_body'},
          ),
          ElementPlaceholder(
            id: 'citation',
            type: 'content',
            position: Offset(80, 450),
            size: Size(640, 30),
            properties: {'maxLength': 100, 'style': 'citation'},
          ),
        ],
        colorScheme: ColorScheme(
          primary: Color(0xFFFF9800),
          secondary: Color(0xFFF57C00),
          accent: Color(0xFF795548),
          background: Color(0xFFFAFAFA),
          surface: Color(0xFFFFFFFF),
          text: Color(0xFF424242),
          textSecondary: Color(0xFF757575),
        ),
        typography: Typography(
          titleFontFamily: 'Times New Roman',
          bodyFontFamily: 'Times New Roman',
          titleFontSize: 24.0,
          bodyFontSize: 14.0,
          titleFontWeight: FontWeight.bold,
          bodyFontWeight: FontWeight.normal,
        ),
        background: BackgroundStyle(
          type: 'solid',
          solidColor: Color(0xFFFAFAFA),
        ),
      ),
    ],
    designRules: {
      'spacing': 'structured',
      'alignment': 'left',
      'emphasis': 'content',
      'visual_hierarchy': 'academic',
    },
  );

      /// Modern Tech 템플릿
    static DesignTemplate get modernTech => DesignTemplate(
    id: 'modern_tech',
    name: 'Modern Tech',
    category: 'modern',
    description: '현대적이고 기술적인 느낌의 디자인',
    previewImage: 'assets/images/templates/modern_tech_preview.png',
    tags: ['기술', '현대적', '미래지향', '혁신'],
    layouts: [
      SlideLayout(
        id: 'tech_layout',
        name: '기술 레이아웃',
        description: '기술적 내용을 시각적으로 표현하는 레이아웃',
        placeholders: [
          ElementPlaceholder(
            id: 'title',
            type: 'title',
            position: Offset(80, 80),
            size: Size(500, 60),
            properties: {'maxLength': 50, 'style': 'tech_title'},
          ),
          ElementPlaceholder(
            id: 'tech_icon',
            type: 'icon',
            position: Offset(600, 80),
            size: Size(80, 80),
            properties: {'icon': '⚡', 'style': 'tech_accent'},
          ),
          ElementPlaceholder(
            id: 'feature_list',
            type: 'bullet_list',
            position: Offset(80, 180),
            size: Size(400, 200),
            properties: {'maxItems': 4, 'style': 'tech_features'},
          ),
          ElementPlaceholder(
            id: 'tech_chart',
            type: 'chart',
            position: Offset(500, 180),
            size: Size(300, 200),
            properties: {'chartType': 'progress', 'style': 'tech'},
          ),
        ],
        colorScheme: ColorScheme(
          primary: Color(0xFF00BCD4),
          secondary: Color(0xFF0097A7),
          accent: Color(0xFFFF5722),
          background: Color(0xFF263238),
          surface: Color(0xFF37474F),
          text: Color(0xFFFFFFFF),
          textSecondary: Color(0xFFB0BEC5),
        ),
        typography: Typography(
          titleFontFamily: 'Roboto',
          bodyFontFamily: 'Roboto',
          titleFontSize: 30.0,
          bodyFontSize: 16.0,
          titleFontWeight: FontWeight.w500,
          bodyFontWeight: FontWeight.normal,
        ),
        background: BackgroundStyle(
          type: 'gradient',
          gradientColors: [Color(0xFF263238), Color(0xFF37474F)],
          opacity: 0.9,
        ),
      ),
    ],
    designRules: {
      'spacing': 'modern',
      'alignment': 'balanced',
      'emphasis': 'visual',
      'visual_hierarchy': 'tech',
    },
  );

  /// 카테고리별 템플릿 필터링
  static List<DesignTemplate> getTemplatesByCategory(String category) {
    return defaultTemplates.where((template) => template.category == category).toList();
  }

  /// 태그별 템플릿 검색
  static List<DesignTemplate> searchTemplatesByTag(String tag) {
    return defaultTemplates.where((template) => template.hasTag(tag)).toList();
  }

  /// 템플릿 ID로 템플릿 찾기
  static DesignTemplate? getTemplateById(String id) {
    try {
      return defaultTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 프리미엄 템플릿만 필터링
  static List<DesignTemplate> getPremiumTemplates() {
    return defaultTemplates.where((template) => template.isPremium).toList();
  }

  /// 무료 템플릿만 필터링
  static List<DesignTemplate> getFreeTemplates() {
    return defaultTemplates.where((template) => !template.isPremium).toList();
  }
}
