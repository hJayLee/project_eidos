import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 이미지 추천 결과
class ImageSuggestion {
  const ImageSuggestion({
    required this.id,
    required this.description,
    required this.previewUrl,
    required this.fullUrl,
    required this.photographer,
    required this.photographerUrl,
    this.width,
    this.height,
  });

  final String id;
  final String description;
  final String previewUrl;
  final String fullUrl;
  final String photographer;
  final String photographerUrl;
  final int? width;
  final int? height;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'previewUrl': previewUrl,
      'fullUrl': fullUrl,
      'photographer': photographer,
      'photographerUrl': photographerUrl,
      'width': width,
      'height': height,
    };
  }
}

/// 아이콘 추천 결과
class IconSuggestion {
  const IconSuggestion({
    required this.name,
    required this.collection,
    required this.tags,
    required this.previewSvg,
    required this.downloadUrl,
  });

  final String name;
  final String collection;
  final List<String> tags;
  final String previewSvg;
  final String downloadUrl;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'collection': collection,
      'tags': tags,
      'previewSvg': previewSvg,
      'downloadUrl': downloadUrl,
    };
  }
}

/// 이미지 & 아이콘 추천 서비스
class AssetSuggestionService {
  AssetSuggestionService({
    http.Client? httpClient,
    String? unsplashAccessKey,
    String? iconifyApiBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _unsplashAccessKey =
           unsplashAccessKey ?? const String.fromEnvironment(_unsplashKeyEnv),
       _iconifyApiBaseUrl = iconifyApiBaseUrl ?? _defaultIconifyEndpoint {
    if (_unsplashAccessKey.isEmpty) {
      debugPrint('[AssetSuggestion] 경고: Unsplash 키가 비어 있습니다.');
    }
  }

  static const String _unsplashKeyEnv = 'UNSPLASH_ACCESS_KEY';
  static const String _defaultIconifyEndpoint = 'https://api.iconify.design';

  final http.Client _httpClient;
  final String _unsplashAccessKey;
  final String _iconifyApiBaseUrl;

  /// 이미지 추천 가져오기
  Future<List<ImageSuggestion>> fetchImageSuggestions(
    String query, {
    int limit = 4,
  }) async {
    if (_unsplashAccessKey.isEmpty || query.trim().isEmpty) {
      return const [];
    }

    final uri =
        Uri.parse(
          'https://api.unsplash.com/search/photos'.replaceAll(' ', ''),
        ).replace(
          queryParameters: {
            'query': query,
            'per_page': '$limit',
            'orientation': 'landscape',
          },
        );

    final response = await _httpClient.get(
      uri,
      headers: {'Authorization': 'Client-ID $_unsplashAccessKey'},
    );

    if (response.statusCode != 200) {
      debugPrint(
        '[AssetSuggestion] Unsplash 호출 실패: ${response.statusCode} ${response.body}',
      );
      return const [];
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final urls = item['urls'] as Map<String, dynamic>? ?? {};
          final user = item['user'] as Map<String, dynamic>? ?? {};
          return ImageSuggestion(
            id: item['id'] as String? ?? '',
            description:
                (item['description'] ?? item['alt_description'] ?? query)
                    as String,
            previewUrl: urls['small'] as String? ?? '',
            fullUrl: urls['regular'] as String? ?? '',
            photographer: user['name'] as String? ?? 'Unknown',
            photographerUrl: user['links']?['html'] as String? ?? '',
            width: item['width'] as int?,
            height: item['height'] as int?,
          );
        })
        .where((suggestion) => suggestion.previewUrl.isNotEmpty)
        .toList();
  }

  /// 아이콘 추천 가져오기
  Future<List<IconSuggestion>> fetchIconSuggestions(
    List<String> keywords, {
    int limit = 6,
  }) async {
    if (keywords.isEmpty) return const [];

    final query = keywords.take(3).join(' ');
    final uri = Uri.parse(
      '$_iconifyApiBaseUrl/search'.replaceAll(' ', ''),
    ).replace(queryParameters: {'query': query, 'limit': '$limit'});

    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        debugPrint(
          '[AssetSuggestion] Iconify 호출 실패: ${response.statusCode} ${response.body}',
        );
        return const [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final icons = decoded['icons'];
      if (icons is! List) return const [];

      return icons
          .whereType<Map<String, dynamic>>()
          .map((icon) {
            final name = icon['name'] as String? ?? '';
            final collection = icon['collection'] as String? ?? 'unknown';
            final tags =
                (icon['tags'] as List?)?.whereType<String>().toList() ?? [];
            final previewSvg =
                icon['previewSVG'] as String? ??
                '<svg xmlns="http://www.w3.org/2000/svg"></svg>';
            final downloadUrl =
                icon['downloadUrl'] as String? ??
                '$_iconifyApiBaseUrl/$collection/$name.svg';
            return IconSuggestion(
              name: name,
              collection: collection,
              tags: tags,
              previewSvg: previewSvg,
              downloadUrl: downloadUrl,
            );
          })
          .where((icon) => icon.name.isNotEmpty)
          .toList();
    } catch (error, stackTrace) {
      debugPrint('[AssetSuggestion] Iconify 예외: $error\n$stackTrace');
      return const [];
    }
  }

  /// 이미지 & 아이콘 한번에 가져오기
  Future<Map<String, dynamic>> fetchSuggestions({
    String? imagePrompt,
    List<String>? iconKeywords,
  }) async {
    final imageSuggestions =
        (imagePrompt != null && imagePrompt.trim().isNotEmpty)
        ? await fetchImageSuggestions(imagePrompt)
        : const <ImageSuggestion>[];

    final iconSuggestions = (iconKeywords != null && iconKeywords.isNotEmpty)
        ? await fetchIconSuggestions(iconKeywords)
        : const <IconSuggestion>[];

    return {
      'images': imageSuggestions.map((image) => image.toJson()).toList(),
      'icons': iconSuggestions.map((icon) => icon.toJson()).toList(),
    };
  }

  void dispose() {
    _httpClient.close();
  }
}
