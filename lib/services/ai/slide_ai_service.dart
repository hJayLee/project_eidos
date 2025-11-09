import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../data/models/script.dart';
import '../../data/models/slide.dart';

/// AI 기반 슬라이드 생성 서비스
class SlideAIService {
  static const String _openaiApiUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String _apiKeyEnvVar = 'OPENAI_API_KEY';

  static String get _apiKey {
    const key = String.fromEnvironment(_apiKeyEnvVar);
    if (key.isEmpty) {
      throw StateError(
        'OpenAI API 키가 설정되지 않았습니다. '
        '"flutter run --dart-define=$_apiKeyEnvVar=YOUR_KEY" 형식으로 전달하세요.',
      );
    }
    return key;
  }

  /// 스크립트를 기반으로 슬라이드 생성
  static Future<List<SlideData>> generateSlidesFromScript({
    required Script script,
    required TemplateCategory category,
    int maxSlides = 10,
  }) async {
    try {
      // 1. 스크립트 분석 및 챕터 생성
      final chapters = script.generateChapters();
      if (chapters.isEmpty) {
        throw Exception('스크립트에서 챕터를 추출할 수 없습니다');
      }

      final slides = <SlideData>[];
      
      // 2. 각 챕터별로 슬라이드 생성
      for (int i = 0; i < chapters.length && i < maxSlides; i++) {
        final chapter = chapters[i];
        
        try {
          final slideContent = await _generateSlideContentWithAI(
            title: chapter.title,
            content: chapter.content,
            category: category,
            slideNumber: i + 1,
            totalSlides: chapters.length,
          );
          
          final slide = await _createSlideFromAIResponse(
            slideContent: slideContent,
            chapter: chapter,
            order: i,
          );
          
          slides.add(slide);
          
          // API 호출 간격 조절 (rate limiting 방지)
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('슬라이드 ${i + 1} 생성 실패: $e');
          
          // AI 생성 실패 시 기본 슬라이드 생성
          final fallbackSlide = _createFallbackSlide(chapter, i);
          slides.add(fallbackSlide);
        }
      }
      
      return slides;
    } catch (e) {
      throw Exception('AI 슬라이드 생성 실패: $e');
    }
  }

  /// 슬라이드용 스크립트 생성
  static Future<String> generateScriptForSlide({
    required SlideData slide,
    required TemplateCategory category,
    String? projectDescription,
    String? voiceTone,
  }) async {
    final bulletPoints = slide.elements
        .where((element) =>
            element.type == SlideElementType.text &&
            element.data['style']?.toString().toLowerCase() == 'bullet')
        .map((element) => element.data['text']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList();

    final paragraphTexts = slide.elements
        .where((element) => element.type == SlideElementType.text)
        .map((element) => element.data['text']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList();

    final response = await _generateScriptWithAI(
      title: slide.title,
      bulletPoints: bulletPoints,
      additionalText: paragraphTexts.join('\n'),
      category: category,
      projectDescription: projectDescription,
      voiceTone: voiceTone,
    );

    return response.trim();
  }

  /// AI를 사용하여 슬라이드 콘텐츠 생성
  static Future<Map<String, dynamic>> _generateSlideContentWithAI({
    required String title,
    required String content,
    required TemplateCategory category,
    required int slideNumber,
    required int totalSlides,
  }) async {
    final systemPrompt = _buildSystemPrompt(category);
    final userPrompt = _buildUserPrompt(
      title: title,
      content: content,
      slideNumber: slideNumber,
      totalSlides: totalSlides,
    );

    final response = await http.post(
      Uri.parse(_openaiApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'max_tokens': 1500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API 호출 실패: ${response.statusCode} - ${response.body}');
    }

    final jsonResponse = jsonDecode(response.body);
    final aiContent = jsonResponse['choices'][0]['message']['content'];
    
    // JSON 응답 파싱
    try {
      final cleanedContent = _cleanJsonResponse(aiContent);
      return jsonDecode(cleanedContent);
    } catch (e) {
      throw Exception('AI 응답 파싱 실패: $e\n원본 응답: $aiContent');
    }
  }

  /// 시스템 프롬프트 생성
  static String _buildSystemPrompt(TemplateCategory category) {
    String categoryGuidance = '';
    
    switch (category) {
      case TemplateCategory.business:
        categoryGuidance = '''
- 비즈니스 관점에서 실용적이고 전문적인 내용
- 데이터, 차트, 통계를 포함한 객관적 정보
- 명확한 결론과 액션 아이템''';
        break;
      case TemplateCategory.education:
        categoryGuidance = '''
- 교육적 가치가 높은 체계적인 내용
- 단계별 설명과 예시 포함
- 학습자가 이해하기 쉬운 구조''';
        break;
      case TemplateCategory.technology:
        categoryGuidance = '''
- 기술적 정확성과 최신 트렌드 반영
- 실제 구현 예시와 코드 스니펫
- 기술적 이점과 한계 설명''';
        break;
      default:
        categoryGuidance = '''
- 명확하고 논리적인 구조
- 핵심 포인트 강조
- 시각적으로 매력적인 요소''';
    }

    return '''당신은 전문적인 프레젠테이션 디자이너입니다.

카테고리별 가이드라인:
$categoryGuidance

다음 JSON 형식으로 정확히 응답해주세요:
{
  "title": "슬라이드 제목",
  "elements": [
    {
      "type": "title",
      "content": "메인 제목",
      "position": {"x": 100, "y": 80},
      "size": {"width": 800, "height": 100},
      "style": {
        "fontSize": 32,
        "fontWeight": "bold",
        "color": "#1a1a1a",
        "textAlign": "center"
      }
    },
    {
      "type": "text",
      "content": "본문 내용",
      "position": {"x": 100, "y": 200},
      "size": {"width": 800, "height": 400},
      "style": {
        "fontSize": 18,
        "fontWeight": "normal",
        "color": "#333333",
        "textAlign": "left"
      }
    }
  ],
  "keyPoints": ["핵심 포인트 1", "핵심 포인트 2", "핵심 포인트 3"],
  "visualSuggestions": ["차트 추가", "이미지 삽입", "아이콘 사용"]
}

중요: 순수한 JSON만 응답하고, 다른 텍스트나 설명은 포함하지 마세요.''';
  }

  /// 사용자 프롬프트 생성
  static String _buildUserPrompt({
    required String title,
    required String content,
    required int slideNumber,
    required int totalSlides,
  }) {
    return '''다음 챕터 내용을 기반으로 전문적인 슬라이드를 생성해주세요:

제목: $title
내용: $content

슬라이드 정보:
- 현재 슬라이드: $slideNumber / $totalSlides
- 16:9 비율 (1920x1080)
- 최대 요소 수: 5개

요구사항:
1. 제목과 본문을 포함한 명확한 구조
2. 핵심 내용을 3-5개의 키포인트로 정리
3. 시각적 요소 제안 (차트, 이미지, 아이콘 등)
4. 읽기 쉽고 전문적인 레이아웃

JSON 형식으로만 응답해주세요.''';
  }

  /// JSON 응답 정리
  static String _cleanJsonResponse(String content) {
    // 코드 블록 제거
    content = content.replaceAll(RegExp(r'```json\s*'), '');
    content = content.replaceAll(RegExp(r'```\s*'), '');
    
    // 앞뒤 공백 제거
    content = content.trim();
    
    // JSON 시작/끝 찾기
    final startIndex = content.indexOf('{');
    final endIndex = content.lastIndexOf('}');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      content = content.substring(startIndex, endIndex + 1);
    }
    
    return content;
  }

  /// AI 응답을 SlideData로 변환
  static Future<SlideData> _createSlideFromAIResponse({
    required Map<String, dynamic> slideContent,
    required ScriptChapter chapter,
    required int order,
  }) async {
    final slide = SlideData.create(
      title: slideContent['title'] ?? chapter.title,
      order: order,
    );

    final elements = <SlideElement>[];
    final elementsData = slideContent['elements'] as List? ?? [];

    for (final elementData in elementsData) {
      try {
        final element = _createSlideElement(elementData);
        elements.add(element);
      } catch (e) {
        print('요소 생성 실패: $e');
      }
    }

    // 기본 요소가 없으면 제목과 본문 추가
    if (elements.isEmpty) {
      elements.addAll(_createDefaultElements(chapter));
    }

    final keyPoints = (slideContent['keyPoints'] as List?)
            ?.map((point) => point?.toString().trim())
            .where((point) => point != null && point.isNotEmpty)
            .cast<String>()
            .toList() ??
        [];

    if (keyPoints.isNotEmpty) {
      final bulletElements = [
        for (final point in keyPoints)
          SlideElement.create(
            type: SlideElementType.text,
            data: {
              'text': point,
              'style': 'bullet',
                  'listType': 'bullet',
            },
          ),
      ];
      elements.addAll(bulletElements);
    }

    return slide.copyWith(elements: elements);
  }

  static Future<String> _generateScriptWithAI({
    required String title,
    required List<String> bulletPoints,
    required String additionalText,
    required TemplateCategory category,
    String? projectDescription,
    String? voiceTone,
  }) async {
    final systemPrompt = _buildScriptSystemPrompt(category, voiceTone);
    final userPrompt = _buildScriptUserPrompt(
      title: title,
      bulletPoints: bulletPoints,
      additionalText: additionalText,
      projectDescription: projectDescription,
      voiceTone: voiceTone,
    );

    final response = await http.post(
      Uri.parse(_openaiApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'max_tokens': 800,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI API 호출 실패: ${response.statusCode} - ${response.body}');
    }

    final jsonResponse = jsonDecode(response.body);
    final content = jsonResponse['choices'][0]['message']['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw Exception('AI로부터 유효한 스크립트를 받지 못했습니다.');
    }

    return content;
  }

  static String _buildScriptSystemPrompt(
    TemplateCategory category,
    String? voiceTone,
  ) {
    final toneDescription = switch (voiceTone?.toLowerCase()) {
      'friendly' || '친근한' => '따뜻하고 친근한',
      'professional' || '전문적인' => '전문적이고 신뢰감 있는',
      'enthusiastic' || '열정적인' => '열정적이고 에너지 넘치는',
      'calm' || '차분한' => '차분하고 안정적인',
      _ => '청중의 집중을 끄는 자연스러운',
    };

    final categoryContext = switch (category) {
      TemplateCategory.presentation =>
        '전반적인 프레젠테이션 상황에 맞춰 청중의 집중을 유지하고, 핵심 메시지를 반복 강조합니다.',
      TemplateCategory.business =>
        '비즈니스 청중에게 실용적인 통찰을 제공하고, 핵심 액션 아이템을 강조합니다.',
      TemplateCategory.education =>
        '학습자 친화적인 언어로 개념을 설명하고, 단계적으로 이해를 도와야 합니다.',
      TemplateCategory.marketing =>
        '제품/서비스의 가치와 혜택을 명확히 전달하며, 설득력 있는 구성을 유지해야 합니다.',
      TemplateCategory.technology =>
        '기술적 정확성을 유지하면서도 비전문가도 이해할 수 있도록 설명해야 합니다.',
      TemplateCategory.creative =>
        '창의적이고 감성적인 언어로 스토리텔링을 강화하고, 영감을 주는 메시지를 전달합니다.',
      TemplateCategory.ai_video_editing =>
        'AI 기반 영상 제작의 장점을 설명하고, 자동화된 프로세스의 효율성을 강조합니다.',
      TemplateCategory.business_automation =>
        '업무 자동화를 통한 생산성 향상과 비용 절감을 명확히 전달하고, 구체적 사례를 통해 설득합니다.',
    };

    return '''
당신은 전문 발표자를 돕는 스크립트 라이터입니다.
$categoryContext
톤은 $toneDescription 화법을 유지하세요.

출력 형식 지침:
- 자연스러운 구어체 문장으로 작성
- 각 문장은 15~25단어 내외를 유지
- 너무 장황하지 않게 핵심 메시지를 우선 전달
- 청중의 관심을 끌기 위한 도입, 핵심 설명, 마무리 멘트를 포함
- 부자연스러운 번역체 표현을 피하고, 매끄러운 한국어를 사용
''';
  }

  static String _buildScriptUserPrompt({
    required String title,
    required List<String> bulletPoints,
    required String additionalText,
    String? projectDescription,
    String? voiceTone,
  }) {
    final buffer = StringBuffer()
      ..writeln('슬라이드 제목: $title')
      ..writeln();

    if (projectDescription != null && projectDescription.trim().isNotEmpty) {
      buffer.writeln('프로젝트 설명: ${projectDescription.trim()}');
      buffer.writeln();
    }

    if (bulletPoints.isNotEmpty) {
      buffer.writeln('핵심 포인트:');
      for (final point in bulletPoints) {
        buffer.writeln('- ${point.trim()}');
      }
      buffer.writeln();
    }

    if (additionalText.trim().isNotEmpty) {
      buffer.writeln('참고 텍스트:');
      buffer.writeln(additionalText.trim());
      buffer.writeln();
    }

    buffer
      ..writeln('요청 사항:')
      ..writeln('1. 위 내용을 기반으로 120~220자 내외의 발표용 스크립트를 작성하세요.')
      ..writeln('2. 서론→전개→결론 흐름을 따르되, 부자연스러운 연결어는 피하세요.')
      ..writeln(
          '3. 청중에게 말을 건네는 것처럼 자연스럽게 작성하고, 불필요한 형식적 문장은 제거하세요.')
      ..writeln('4. 결과는 순수한 문장들로만 반환하고 따로 머리말이나 끝맺음 문구는 넣지 마세요.');

    return buffer.toString();
  }

  /// SlideElement 생성
  static SlideElement _createSlideElement(Map<String, dynamic> elementData) {
    final type = _parseElementType(elementData['type']?.toString() ?? 'text');
    final position = _parsePosition(elementData['position']);
    final size = _parseSize(elementData['size']);
    final style = _parseStyle(elementData['style']);
    final content = elementData['content']?.toString() ?? '';

    final data = Map<String, dynamic>.from(elementData);
    data['text'] = content;
    if (!data.containsKey('style')) {
      data['style'] = type == SlideElementType.text ? 'body' : '';
    }

    return SlideElement.create(
      type: type,
      data: data,
      position: position,
      size: size,
    ).copyWith(style: style);
  }

  /// 요소 타입 파싱
  static SlideElementType _parseElementType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'title':
      case 'text':
        return SlideElementType.text;
      case 'image':
        return SlideElementType.image;
      case 'chart':
        return SlideElementType.chart;
      case 'table':
        return SlideElementType.table;
      case 'icon':
        return SlideElementType.icon;
      case 'shape':
        return SlideElementType.shape;
      default:
        return SlideElementType.text;
    }
  }

  /// 위치 파싱
  static ElementPosition _parsePosition(dynamic positionData) {
    if (positionData is Map<String, dynamic>) {
      return ElementPosition(
        x: (positionData['x'] as num?)?.toDouble() ?? 100,
        y: (positionData['y'] as num?)?.toDouble() ?? 100,
      );
    }
    return const ElementPosition(x: 100, y: 100);
  }

  /// 크기 파싱
  static ElementSize _parseSize(dynamic sizeData) {
    if (sizeData is Map<String, dynamic>) {
      return ElementSize(
        width: (sizeData['width'] as num?)?.toDouble() ?? 400,
        height: (sizeData['height'] as num?)?.toDouble() ?? 100,
      );
    }
    return const ElementSize(width: 400, height: 100);
  }

  /// 스타일 파싱
  static ElementStyle _parseStyle(dynamic styleData) {
    if (styleData is Map<String, dynamic>) {
      return ElementStyle(
        fontSize: (styleData['fontSize'] as num?)?.toDouble(),
        fontWeight: styleData['fontWeight']?.toString(),
        color: styleData['color']?.toString(),
        backgroundColor: styleData['backgroundColor']?.toString(),
        textAlign: styleData['textAlign']?.toString(),
      );
    }
    return ElementStyle.defaultForType(SlideElementType.text);
  }

  /// 기본 요소 생성 (AI 실패 시 폴백)
  static List<SlideElement> _createDefaultElements(ScriptChapter chapter) {
    return [
      SlideElement.create(
        type: SlideElementType.text,
        data: {
          'text': chapter.title,
          'style': 'title',
        },
        position: const ElementPosition(x: 100, y: 80),
        size: const ElementSize(width: 800, height: 100),
      ),
      SlideElement.create(
        type: SlideElementType.text,
        data: {
          'text': chapter.content,
          'style': 'body',
        },
        position: const ElementPosition(x: 100, y: 200),
        size: const ElementSize(width: 800, height: 400),
      ),
    ];
  }

  /// 폴백 슬라이드 생성
  static SlideData _createFallbackSlide(ScriptChapter chapter, int order) {
    final slide = SlideData.create(
      title: chapter.title,
      order: order,
    );

    final elements = _createDefaultElements(chapter);
    return slide.copyWith(elements: elements);
  }
}


