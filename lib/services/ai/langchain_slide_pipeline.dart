import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/script.dart';
import '../../data/models/slide.dart';
import 'asset_suggestion_service.dart';
import 'slide_generation_service.dart';

/// LangChain 스타일로 구성한 슬라이드 생성 파이프라인 컨텍스트
class GenerationContext {
  const GenerationContext({
    required this.projectId,
    required this.request,
    this.script,
    this.metadata = const {},
  });

  final String projectId;
  final SlideGenerationRequest request;
  final Script? script;
  final Map<String, dynamic> metadata;

  GenerationContext copyWith({
    String? projectId,
    SlideGenerationRequest? request,
    Script? script,
    Map<String, dynamic>? metadata,
  }) {
    return GenerationContext(
      projectId: projectId ?? this.projectId,
      request: request ?? this.request,
      script: script ?? this.script,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 외부 검색 결과 세트
class ExternalFactSet {
  const ExternalFactSet({required this.facts});

  final List<WebSearchResult> facts;

  bool get isEmpty => facts.isEmpty;
}

/// LangChain 기반 슬라이드 생성 파이프라인
class LangChainSlidePipeline {
  LangChainSlidePipeline({
    required SlideGenerationService generationService,
    AssetSuggestionService? assetSuggestionService,
  }) : _generationService = generationService,
       _assetSuggestionService = assetSuggestionService;

  final SlideGenerationService _generationService;
  final AssetSuggestionService? _assetSuggestionService;

  /// 전체 파이프라인 실행
  Future<List<SlideData>> run({required GenerationContext context}) async {
    debugPrint('[LangChainPipeline] 입력 수집 완료: ${context.projectId}');

    final slides = await _generationService.generateSlides(
      request: context.request,
      projectId: context.projectId,
    );

    debugPrint('[LangChainPipeline] 슬라이드 생성 완료: ${slides.length}개');

    if (_assetSuggestionService == null) {
      return slides;
    }

    final usedImageUrls = <String>{};
    final usedIconKeys = <String>{};
    final enrichedSlides = <SlideData>[];

    for (final slide in slides) {
      final enriched = await _attachAssetSuggestions(
        slide,
        usedImageUrls,
        usedIconKeys,
      );
      enrichedSlides.add(enriched);
    }

    return enrichedSlides;
  }

  Future<SlideData> _attachAssetSuggestions(
    SlideData slide,
    Set<String> usedImageUrls,
    Set<String> usedIconKeys,
  ) async {
    final metadata = slide.metadata;
    final imagePrompt = metadata['imagePrompt'] as String?;
    final iconKeywords = (metadata['iconKeywords'] as List?)
        ?.whereType<String>()
        .where((keyword) => keyword.trim().isNotEmpty)
        .toList();

    if ((imagePrompt == null || imagePrompt.trim().isEmpty) &&
        (iconKeywords == null || iconKeywords.isEmpty)) {
      return slide;
    }

    try {
      final suggestions = await _assetSuggestionService!.fetchSuggestions(
        imagePrompt: imagePrompt,
        iconKeywords: iconKeywords,
      );

      SlideData enrichedSlide = slide.copyWith(
        metadata: {...metadata, 'assetSuggestions': suggestions},
      );

      final imageHint = metadata['imagePlacementHint']?.toString();
      final iconHint = metadata['iconPlacementHint']?.toString();

      if (!enrichedSlide.elements.any(
        (element) => element.type == SlideElementType.image,
      )) {
        final image = _pickNextImageSuggestion(suggestions, usedImageUrls);
        if (image != null) {
          final placement = _resolveImagePlacement(
            enrichedSlide.layout,
            imageHint,
          );
          enrichedSlide = enrichedSlide.addElement(
            SlideElement.create(
              type: SlideElementType.image,
              data: {
                'url': image['fullUrl'],
                'previewUrl': image['previewUrl'],
                'description': image['description'],
                'photographer': image['photographer'],
                'photographerUrl': image['photographerUrl'],
                'source': 'unsplash',
              },
              position: placement.position,
              size: placement.size,
            ),
          );
        }
      }

      if (!enrichedSlide.elements.any(
        (element) => element.type == SlideElementType.icon,
      )) {
        final icon = _pickNextIconSuggestion(suggestions, usedIconKeys);
        if (icon != null) {
          final placement = _resolveIconPlacement(
            enrichedSlide.layout,
            iconHint,
          );
          enrichedSlide = enrichedSlide.addElement(
            SlideElement.create(
              type: SlideElementType.icon,
              data: {
                'name': icon['name'],
                'collection': icon['collection'],
                'previewSvg': icon['previewSvg'],
                'downloadUrl': icon['downloadUrl'],
                'tags': icon['tags'],
                'source': 'iconify',
              },
              position: placement.position,
              size: placement.size,
            ),
          );
        }
      }

      return enrichedSlide;
    } catch (error) {
      debugPrint('[LangChainPipeline] 자산 추천 실패: $error');
      return slide;
    }
  }

  Map<String, dynamic>? _pickNextImageSuggestion(
    Map<String, dynamic> suggestions,
    Set<String> usedImageUrls,
  ) {
    if (suggestions['images'] case List images) {
      for (final item in images.whereType<Map<String, dynamic>>()) {
        final url = (item['fullUrl'] ?? item['url']) as String?;
        if (url == null || url.isEmpty) continue;
        if (usedImageUrls.contains(url)) continue;
        usedImageUrls.add(url);
        return item;
      }
    }
    return null;
  }

  Map<String, dynamic>? _pickNextIconSuggestion(
    Map<String, dynamic> suggestions,
    Set<String> usedIconKeys,
  ) {
    if (suggestions['icons'] case List icons) {
      for (final item in icons.whereType<Map<String, dynamic>>()) {
        final key = (item['downloadUrl'] ?? item['name']) as String?;
        if (key == null || key.isEmpty) continue;
        if (usedIconKeys.contains(key)) continue;
        usedIconKeys.add(key);
        return item;
      }
    }
    return null;
  }

  _ElementPlacement _resolveImagePlacement(SlideLayout layout, String? hint) {
    final normalized = hint?.toLowerCase();
    switch (normalized) {
      case 'hero-left':
        return const _ElementPlacement(
          ElementPosition(x: 96, y: 180),
          ElementSize(width: 360, height: 260),
        );
      case 'hero-right':
        return const _ElementPlacement(
          ElementPosition(x: 520, y: 180),
          ElementSize(width: 360, height: 260),
        );
      case 'full-bleed':
        return const _ElementPlacement(
          ElementPosition(x: 40, y: 40),
          ElementSize(width: 880, height: 500),
        );
      case 'split-left':
        return const _ElementPlacement(
          ElementPosition(x: 96, y: 200),
          ElementSize(width: 320, height: 240),
        );
      case 'split-right':
        return const _ElementPlacement(
          ElementPosition(x: 540, y: 200),
          ElementSize(width: 320, height: 240),
        );
    }

    switch (layout) {
      case SlideLayout.fullImage:
        return const _ElementPlacement(
          ElementPosition(x: 32, y: 32),
          ElementSize(width: 896, height: 512),
        );
      case SlideLayout.imageAndText:
      case SlideLayout.twoColumns:
        return const _ElementPlacement(
          ElementPosition(x: 520, y: 180),
          ElementSize(width: 320, height: 240),
        );
      default:
        return const _ElementPlacement(
          ElementPosition(x: 440, y: 200),
          ElementSize(width: 320, height: 220),
        );
    }
  }

  _ElementPlacement _resolveIconPlacement(SlideLayout layout, String? hint) {
    final normalized = hint?.toLowerCase();
    switch (normalized) {
      case 'top-right':
        return const _ElementPlacement(
          ElementPosition(x: 760, y: 64),
          ElementSize(width: 96, height: 96),
        );
      case 'top-left':
        return const _ElementPlacement(
          ElementPosition(x: 80, y: 64),
          ElementSize(width: 96, height: 96),
        );
      case 'bottom-right':
        return const _ElementPlacement(
          ElementPosition(x: 760, y: 420),
          ElementSize(width: 96, height: 96),
        );
      case 'bottom-left':
        return const _ElementPlacement(
          ElementPosition(x: 80, y: 420),
          ElementSize(width: 96, height: 96),
        );
      case 'inline':
        return const _ElementPlacement(
          ElementPosition(x: 120, y: 180),
          ElementSize(width: 72, height: 72),
        );
    }

    switch (layout) {
      case SlideLayout.fullImage:
        return const _ElementPlacement(
          ElementPosition(x: 72, y: 72),
          ElementSize(width: 96, height: 96),
        );
      case SlideLayout.imageAndText:
      case SlideLayout.twoColumns:
        return const _ElementPlacement(
          ElementPosition(x: 96, y: 96),
          ElementSize(width: 96, height: 96),
        );
      default:
        return const _ElementPlacement(
          ElementPosition(x: 720, y: 96),
          ElementSize(width: 96, height: 96),
        );
    }
  }
}

class _ElementPlacement {
  const _ElementPlacement(this.position, this.size);

  final ElementPosition position;
  final ElementSize size;
}
