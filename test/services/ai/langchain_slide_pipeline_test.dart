import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:project_eidos/core/constants/app_constants.dart';
import 'package:project_eidos/data/models/slide.dart';
import 'package:project_eidos/services/ai/asset_suggestion_service.dart';
import 'package:project_eidos/services/ai/langchain_slide_pipeline.dart';
import 'package:project_eidos/services/ai/slide_generation_service.dart';

void main() {
  group('LangChainSlidePipeline', () {
    test('adds image and icon elements using asset suggestions', () async {
      final baseSlide = SlideData.create(title: 'AI 소개', order: 0).copyWith(
        metadata: {
          'imagePrompt': 'modern office interior',
          'imagePlacementHint': 'hero-right',
          'iconKeywords': ['ai', 'robot'],
          'iconPlacementHint': 'top-right',
        },
      );

      final pipeline = LangChainSlidePipeline(
        generationService: _FakeSlideGenerationService([baseSlide]),
        assetSuggestionService: _FakeAssetSuggestionService(),
      );

      final result = await pipeline.run(
        context: GenerationContext(
          projectId: 'project-1',
          request: SlideGenerationRequest(title: 'AI 소개', overview: 'AI 개요'),
        ),
      );

      final slide = result.first;
      expect(
        slide.elements.any((element) => element.type == SlideElementType.image),
        isTrue,
      );
      expect(
        slide.elements.any((element) => element.type == SlideElementType.icon),
        isTrue,
      );

      final imageElement = slide.elements.firstWhere(
        (element) => element.type == SlideElementType.image,
      );
      final iconElement = slide.elements.firstWhere(
        (element) => element.type == SlideElementType.icon,
      );

      expect(imageElement.data['url'], 'https://images.unsplash.com/full');
      expect(imageElement.position.x, 520);
      expect(imageElement.position.y, 180);

      expect(
        iconElement.data['downloadUrl'],
        'https://iconify.design/mdi/robot.svg',
      );
      expect(iconElement.position.x, 760);
      expect(iconElement.position.y, 64);
    });
  });
}

class _FakeSlideGenerationService extends SlideGenerationService {
  _FakeSlideGenerationService(this._slides)
    : super(
        llmClient: _FakeLlmClient(),
        webSearchClient: _FakeWebSearchClient(),
      );

  final List<SlideData> _slides;

  @override
  Future<List<SlideData>> generateSlides({
    required SlideGenerationRequest request,
    String? projectId,
  }) async {
    return _slides;
  }
}

class _FakeLlmClient implements LlmClient {
  @override
  Future<String> generate({
    required String prompt,
    Map<String, dynamic>? options,
  }) {
    return Future.value('{}');
  }
}

class _FakeWebSearchClient implements WebSearchClient {
  @override
  Future<List<WebSearchResult>> search({
    required String query,
    int maxResults = 2,
  }) {
    return Future.value(const []);
  }
}

class _FakeAssetSuggestionService extends AssetSuggestionService {
  _FakeAssetSuggestionService()
    : super(httpClient: http.Client(), unsplashAccessKey: 'fake');

  @override
  Future<Map<String, dynamic>> fetchSuggestions({
    String? imagePrompt,
    List<String>? iconKeywords,
  }) async {
    return {
      'images': [
        {
          'fullUrl': 'https://images.unsplash.com/full',
          'previewUrl': 'https://images.unsplash.com/preview',
          'description': 'Modern tech office',
          'photographer': 'Jane Doe',
          'photographerUrl': 'https://unsplash.com/@jane',
        },
      ],
      'icons': [
        {
          'name': 'mdi:robot',
          'collection': 'mdi',
          'previewSvg': '<svg></svg>',
          'downloadUrl': 'https://iconify.design/mdi/robot.svg',
          'tags': ['robot', 'ai'],
        },
      ],
    };
  }
}
