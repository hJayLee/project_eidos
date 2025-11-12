import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/models/slide.dart';
import '../../core/constants/app_constants.dart' show SlideElementType;

/// 요청자가 입력한 프롬프트 정보
class SlideGenerationRequest {
  const SlideGenerationRequest({
    required this.title,
    required this.overview,
    this.customBullets = const [],
    this.desiredSlideCount,
    this.tone,
    this.targetAudience,
    this.additionalContext,
  });

  final String title;
  final String overview;
  final List<String> customBullets;
  final int? desiredSlideCount;
  final String? tone;
  final String? targetAudience;
  final String? additionalContext;
}

/// 슬라이드 생성 결과 메타데이터
class SlideGenerationMetadata {
  const SlideGenerationMetadata({required this.references});

  final List<String> references;
}

/// LLM 호출을 추상화한 인터페이스
abstract class LlmClient {
  Future<String> generate({
    required String prompt,
    Map<String, dynamic>? options,
  });
}

/// 웹 검색/팩트 수집 추상화
abstract class WebSearchClient {
  Future<List<WebSearchResult>> search({required String query, int maxResults});
}

class WebSearchResult {
  const WebSearchResult({
    required this.title,
    required this.snippet,
    required this.url,
  });

  final String title;
  final String snippet;
  final String url;
}

/// 슬라이드 생성 예외
class SlideGenerationException implements Exception {
  SlideGenerationException(this.message, {this.details});

  final String message;
  final Object? details;

  @override
  String toString() =>
      'SlideGenerationException(message: $message, details: $details)';
}

class SlideGenerationService {
  SlideGenerationService({
    required this.llmClient,
    required this.webSearchClient,
  });

  final LlmClient llmClient;
  final WebSearchClient webSearchClient;

  static const int _defaultSlideCount = 8;
  static const int _maxFacts = 5;

  Future<List<SlideData>> generateSlides({
    required SlideGenerationRequest request,
    String? projectId,
  }) async {
    final facts = await _collectFacts(request);
    final prompt = _buildPrompt(request: request, facts: facts);

    late final String rawResponse;
    try {
      rawResponse = await llmClient.generate(
        prompt: prompt,
        options: {'temperature': 0.4, 'response_format': 'json_object'},
      );
    } catch (error, stackTrace) {
      debugPrint('[SlideGeneration] LLM 호출 실패: $error');
      Error.throwWithStackTrace(
        SlideGenerationException('LLM 호출에 실패했습니다.', details: error),
        stackTrace,
      );
    }

    final records = _parseResponse(rawResponse);
    return _mapToSlides(records, request);
  }

  Future<List<WebSearchResult>> _collectFacts(
    SlideGenerationRequest request,
  ) async {
    final queries = <String>{request.title};
    if (request.overview.isNotEmpty) {
      queries.add(request.overview);
    }
    queries.addAll(
      request.customBullets.where((bullet) => bullet.trim().isNotEmpty),
    );

    final results = <WebSearchResult>[];
    for (final query in queries) {
      try {
        final searchResults = await webSearchClient.search(
          query: query,
          maxResults: 2,
        );
        results.addAll(searchResults);
        if (results.length >= _maxFacts) break;
      } catch (error) {
        debugPrint('[SlideGeneration] 웹 검색 실패 ($query): $error');
      }
    }
    return results.take(_maxFacts).toList();
  }

  String _buildPrompt({
    required SlideGenerationRequest request,
    required List<WebSearchResult> facts,
  }) {
    final slideCount = request.desiredSlideCount ?? _defaultSlideCount;

    final buffer = StringBuffer()
      ..writeln('당신은 프리미엄 슬라이드 디자이너입니다. 사용자의 프롬프트를 바탕으로 전문적인 슬라이드를 생성하세요.')
      ..writeln('출력은 반드시 JSON 형식으로 작성합니다.')
      ..writeln()
      ..writeln('### 요구사항')
      ..writeln('- 슬라이드 개수: $slideCount')
      ..writeln('- 슬라이드 수준: SkyworkAI와 동일 혹은 그 이상')
      ..writeln('- 각 슬라이드는 제목, bullet 3~5개, 2~3문장의 본문 요약(body)을 포함합니다.')
      ..writeln('- bullet은 핵심적인 메시지를 담고, 서로 중복되지 않도록 합니다.')
      ..writeln('- body에는 bullet이 다루지 못한 배경/맥락을 자연스러운 문장으로 작성합니다.')
      ..writeln('- 이미지와 아이콘은 실제 사용자가 교체할 수 있도록, 생성/검색 시 참고할 설명만 제공합니다.')
      ..writeln(
        '- imagePlacementHint 필드에는 hero-left, hero-right, full-bleed, split-right, split-left 중 하나를 사용하세요.',
      )
      ..writeln(
        '- iconPlacementHint 필드에는 top-right, top-left, bottom-right, bottom-left, inline 중 하나를 사용하세요.',
      )
      ..writeln('- 모든 사실 관계는 제공된 최신 정보(facts)를 우선 적용하고, 확인되지 않은 내용은 추측하지 않습니다.')
      ..writeln('- 각 슬라이드는 references 배열에 bullet/body에서 인용한 출처 URL을 포함합니다.')
      ..writeln()
      ..writeln('### 사용자 입력')
      ..writeln('- 제목: ${request.title}')
      ..writeln('- 개요: ${request.overview}')
      ..writeln(
        '- 선택 지정 bullet: ${request.customBullets.isEmpty ? '없음' : request.customBullets.join(" | ")}',
      )
      ..writeln('- 톤/스타일: ${request.tone ?? '전문적이고 명확한 톤'}')
      ..writeln('- 대상 청중: ${request.targetAudience ?? '일반 비즈니스 프레젠테이션'}')
      ..writeln('- 추가 컨텍스트: ${request.additionalContext ?? '없음'}')
      ..writeln()
      ..writeln('### 참고 자료 (facts)');

    if (facts.isEmpty) {
      buffer.writeln('- 제공된 참고 자료 없음');
    } else {
      for (final fact in facts.take(_maxFacts)) {
        buffer
          ..writeln('- ${fact.title} (${fact.url})')
          ..writeln('  ${fact.snippet}');
      }
    }

    buffer
      ..writeln()
      ..writeln('### 출력 형식(JSON 문자열)')
      ..writeln(r'''
{
  "slides": [
    {
      "title": "슬라이드 제목",
      "bullets": ["핵심 bullet", "..."],
      "body": "요약 본문",
      "imagePrompt": "이미지 생성/검색용 설명",
      "imagePlacementHint": "hero-right",
      "iconKeywords": ["keyword1", "keyword2"],
      "iconPlacementHint": "top-right",
      "references": ["https://..."]
    }
  ]
}
''')
      ..writeln()
      ..writeln('JSON 이외의 설명, 코드블록, 불필요한 텍스트는 절대 포함하지 마세요.');

    return buffer.toString();
  }

  List<_SlideDraft> _parseResponse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw SlideGenerationException('LLM 응답이 JSON 객체가 아닙니다.');
      }
      final slides = decoded['slides'];
      if (slides is! List) {
        throw SlideGenerationException('slides 필드가 배열이 아닙니다.');
      }
      final records = slides
          .whereType<Map<String, dynamic>>()
          .map(_SlideDraft.fromJson)
          .where((draft) => draft.title.trim().isNotEmpty)
          .toList();
      if (records.isEmpty) {
        throw SlideGenerationException('슬라이드 데이터가 비어있습니다.');
      }
      return records;
    } on SlideGenerationException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[SlideGeneration] 응답 파싱 실패: $error\n$raw');
      Error.throwWithStackTrace(
        SlideGenerationException('슬라이드 생성 결과 파싱에 실패했습니다.', details: error),
        stackTrace,
      );
    }
  }

  List<SlideData> _mapToSlides(
    List<_SlideDraft> drafts,
    SlideGenerationRequest request,
  ) {
    return drafts.asMap().entries.map((entry) {
      final index = entry.key;
      final draft = entry.value;

      SlideData slide = SlideData.create(title: draft.title, order: index);

      final baseMetadata = {
        ...slide.metadata,
        'imagePrompt': draft.imagePrompt,
        'imagePlacementHint': draft.imagePlacementHint,
        'iconKeywords': draft.iconKeywords,
        'iconPlacementHint': draft.iconPlacementHint,
        'references': draft.references,
      };

      if (draft.body != null && draft.body!.trim().isNotEmpty) {
        slide = slide.copyWith(
          metadata: {
            ...baseMetadata,
            'body': draft.body,
          },
          speakerNotes: draft.body,
        );
      } else {
        slide = slide.copyWith(metadata: baseMetadata);
      }

      for (final bullet in draft.bullets) {
        final element = SlideElement.create(
          type: SlideElementType.text,
          data: {'text': bullet, 'listType': 'bullet', 'style': 'bullet'},
        );
        slide = slide.addElement(element);
      }

      final refs = draft.references;
      if (refs.isNotEmpty) {
        slide = slide.copyWith(
          metadata: {...slide.metadata, 'references': refs},
        );
      }

      return _applyElementLayout(slide);
    }).toList();
  }

  SlideData _applyElementLayout(SlideData slide) {
    SlideElement? titleElement;
    final bulletElements = <SlideElement>[];
    final otherTextElements = <SlideElement>[];
    final imageElements = <SlideElement>[];
    final iconElements = <SlideElement>[];
    final residualElements = <SlideElement>[];

    for (final element in slide.elements) {
      switch (element.type) {
        case SlideElementType.text:
          final styleKey = element.data['style']?.toString().toLowerCase();
          if (styleKey == 'title') {
            titleElement ??= element;
            continue;
          }
          if (styleKey == 'bullet') {
            bulletElements.add(element);
            continue;
          }
          otherTextElements.add(element);
          continue;
        case SlideElementType.image:
          imageElements.add(element);
          continue;
        case SlideElementType.icon:
          iconElements.add(element);
          continue;
        default:
          residualElements.add(element);
      }
    }

    if (titleElement == null && slide.title.trim().isNotEmpty) {
      titleElement = SlideElement.create(
        type: SlideElementType.text,
        data: {'text': slide.title.trim(), 'style': 'title'},
      );
    }

    final hasImage = imageElements.isNotEmpty;
    final textAreaWidth = hasImage ? 420.0 : 720.0;
    const titleTop = 96.0;
    const titleLeft = 96.0;
    const textLeft = 120.0;

    final updatedElements = <SlideElement>[];
    double currentY = titleTop;

    if (titleElement != null) {
      final placedTitle = titleElement.copyWith(
        position: const ElementPosition(x: titleLeft, y: titleTop),
        size: ElementSize(width: textAreaWidth, height: 72),
        style: titleElement.style.copyWith(
          fontSize: 36,
          fontWeight: '700',
          color: '#111827',
          textAlign: 'left',
        ),
      );
      updatedElements.add(placedTitle);
      currentY = titleTop + 72 + 24;
    }

    for (final bullet in bulletElements) {
      final placedBullet = bullet.copyWith(
        position: ElementPosition(x: textLeft, y: currentY),
        size: ElementSize(width: textAreaWidth, height: 48),
        style: bullet.style.copyWith(
          fontSize: 20,
          fontWeight: '500',
          color: '#1F2937',
          textAlign: 'left',
        ),
      );
      updatedElements.add(placedBullet);
      currentY += 52;
    }

    for (final other in otherTextElements) {
      final placedOther = other.copyWith(
        position: ElementPosition(x: textLeft, y: currentY),
        size: ElementSize(width: textAreaWidth, height: 44),
        style: other.style.copyWith(
          fontSize: other.style.fontSize ?? 18,
          color: other.style.color ?? '#4B5563',
          textAlign: other.style.textAlign ?? 'left',
        ),
      );
      updatedElements.add(placedOther);
      currentY += 48;
    }

    if (imageElements.isNotEmpty) {
      double imageY = titleTop + 64;
      final imageLeft = _clampDouble(
        textLeft + textAreaWidth + 40,
        520.0,
        820.0,
      );
      for (final image in imageElements) {
        final placedImage = image.copyWith(
          position: ElementPosition(x: imageLeft, y: imageY),
          size: const ElementSize(width: 360, height: 240),
        );
        updatedElements.add(placedImage);
        imageY += 272;
      }
    }

    if (iconElements.isNotEmpty) {
      double iconY = titleTop;
      final iconLeft = hasImage
          ? _clampDouble(textLeft + textAreaWidth + 320, 680.0, 840.0)
          : 760.0;
      for (final icon in iconElements) {
        final placedIcon = icon.copyWith(
          position: ElementPosition(x: iconLeft, y: iconY),
          size: const ElementSize(width: 88, height: 88),
          style: icon.style.copyWith(
            color: icon.style.color ?? '#3B82F6',
            opacity: 1.0,
          ),
        );
        updatedElements.add(placedIcon);
        iconY += 104;
      }
    }

    updatedElements.addAll(residualElements);

    return slide.copyWith(elements: updatedElements);
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

class _SlideDraft {
  const _SlideDraft({
    required this.title,
    required this.bullets,
    this.body,
    this.imagePrompt,
    this.imagePlacementHint,
    this.iconKeywords = const [],
    this.iconPlacementHint,
    this.references = const [],
  });

  final String title;
  final List<String> bullets;
  final String? body;
  final String? imagePrompt;
  final String? imagePlacementHint;
  final List<String> iconKeywords;
  final String? iconPlacementHint;
  final List<String> references;

  factory _SlideDraft.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(dynamic value) {
      if (value is List) {
        return value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return const [];
    }

    String? readHint(String? value) {
      final trimmed = value?.trim().toLowerCase();
      return trimmed?.isEmpty ?? true ? null : trimmed;
    }

    return _SlideDraft(
      title: (json['title'] as String? ?? '').trim(),
      bullets: readStringList(json['bullets']),
      body: (json['body'] as String?)?.trim(),
      imagePrompt: (json['imagePrompt'] as String?)?.trim(),
      imagePlacementHint: readHint(json['imagePlacementHint'] as String?),
      iconKeywords: readStringList(json['iconKeywords']),
      iconPlacementHint: readHint(json['iconPlacementHint'] as String?),
      references: readStringList(json['references']),
    );
  }
}
