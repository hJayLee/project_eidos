import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/app_constants.dart' show SlideElementType;
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart';

/// 슬라이드 미리보기 패널
class SlidePreviewPanel extends StatelessWidget {
  const SlidePreviewPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlideUpdated,
  });

  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<SlideData> onSlideUpdated;

  @override
  Widget build(BuildContext context) {
    final slide = selectedSlideIndex < project.slides.length
        ? project.slides[selectedSlideIndex]
        : null;

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: slide == null
                ? const _EmptySlidePlaceholder()
                : _SlideStage(
                    slide: slide,
                    slideNumber: selectedSlideIndex + 1,
                    totalSlides: project.slides.length,
                    onSlideUpdated: onSlideUpdated,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SlideStage extends StatelessWidget {
  const _SlideStage({
    required this.slide,
    required this.slideNumber,
    required this.totalSlides,
    required this.onSlideUpdated,
  });

  final SlideData slide;
  final int slideNumber;
  final int totalSlides;
  final ValueChanged<SlideData> onSlideUpdated;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SlideHeader(
            title: slide.title,
            slideNumber: slideNumber,
            totalSlides: totalSlides,
            speakerNotes: slide.speakerNotes,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: _SlideContent(
                slide: slide,
                onSlideUpdated: onSlideUpdated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideHeader extends StatelessWidget {
  const _SlideHeader({
    required this.title,
    required this.slideNumber,
    required this.totalSlides,
    this.speakerNotes,
  });

  final String title;
  final int slideNumber;
  final int totalSlides;
  final String? speakerNotes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.16),
            AppTheme.primaryColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.slideshow, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.isEmpty ? '제목 없는 슬라이드' : title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$slideNumber / $totalSlides',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          if ((speakerNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_outlined,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      speakerNotes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({
    required this.slide,
    required this.onSlideUpdated,
  });

  final SlideData slide;
  final ValueChanged<SlideData> onSlideUpdated;

  @override
  Widget build(BuildContext context) {
    bool isBulletElement(SlideElement element) {
      if (element.type != SlideElementType.text) return false;
      final styleValue = element.data['style']?.toString().toLowerCase();
      return styleValue == 'bullet' ||
          styleValue == 'bulleted' ||
          styleValue == 'list';
    }

    SlideElement? imageElement;
    for (final element in slide.elements) {
      if (element.type == SlideElementType.image) {
        imageElement = element;
        break;
      }
    }

    final bulletElements =
        slide.elements.where((element) => isBulletElement(element)).toList();
    final paragraphElements = slide.elements
        .where((element) =>
            element.type == SlideElementType.text && !isBulletElement(element))
        .toList();

    final chartElements = slide.elements
        .where((element) => element.type == SlideElementType.chart)
        .toList();
    final tableElements = slide.elements
        .where((element) => element.type == SlideElementType.table)
        .toList();
    final iconElements = slide.elements
        .where((element) => element.type == SlideElementType.icon)
        .toList();
    final shapeElements = slide.elements
        .where((element) => element.type == SlideElementType.shape)
        .toList();
    final videoElements = slide.elements
        .where((element) => element.type == SlideElementType.video)
        .toList();
    final animationElements = slide.elements
        .where((element) => element.type == SlideElementType.animation)
        .toList();

    final hasTextContent =
        bulletElements.isNotEmpty || paragraphElements.isNotEmpty;
    final hasVisualContent = imageElement != null;
    final hasSupplementaryElements = [
      chartElements,
      tableElements,
      iconElements,
      shapeElements,
      videoElements,
      animationElements,
    ].any((list) => list.isNotEmpty);

    if (!hasTextContent && !hasVisualContent) {
      return const _EmptyContentHint();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bulletElements.isNotEmpty)
                      _BulletList(elements: bulletElements),
                    if (paragraphElements.isNotEmpty) ...[
                      if (bulletElements.isNotEmpty) const SizedBox(height: 24),
                      _ParagraphBlock(elements: paragraphElements),
                    ],
                    if (!hasTextContent)
                      const _PlaceholderCard(
                        icon: Icons.notes_outlined,
                        title: '텍스트 콘텐츠 없음',
                        subtitle: '핵심 포인트를 추가하거나 AI에게 생성 요청을 해보세요.',
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                flex: 2,
                child: _VisualBlock(element: imageElement),
              ),
            ],
          ),
        ),
        if (hasSupplementaryElements) ...[
          const SizedBox(height: 28),
          _SupplementaryElementPanel(
            chartElements: chartElements,
            tableElements: tableElements,
            iconElements: iconElements,
            shapeElements: shapeElements,
            videoElements: videoElements,
            animationElements: animationElements,
          ),
        ],
      ],
    );
  }
}

class _VisualBlock extends StatelessWidget {
  const _VisualBlock({required this.element});

  final SlideElement? element;

  @override
  Widget build(BuildContext context) {
    final imageUrl = element?.data['url']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      return _PlaceholderCard(
        icon: Icons.image_outlined,
        title: '이미지/비주얼 자료 없음',
        subtitle: '슬라이드에 어울리는 이미지를 추가하면 전달력이 높아집니다.',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.surfaceColor,
              child: Center(
                child: _PlaceholderCard(
                  icon: Icons.broken_image_outlined,
                  title: '이미지를 불러올 수 없습니다',
                  subtitle: '다른 이미지를 선택하거나 다시 시도해주세요.',
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AI 추천 이미지',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _EmptySlidePlaceholder extends StatelessWidget {
  const _EmptySlidePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.slideshow_outlined,
                  size: 64, color: AppTheme.textSecondaryColor),
              const SizedBox(height: 16),
              Text(
                '아직 생성된 슬라이드가 없어요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '좌측 AI 어시스턴트에 강의 개요를 전달하거나\n직접 첫 번째 슬라이드를 만들어보세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContentHint extends StatelessWidget {
  const _EmptyContentHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined,
              size: 56, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 16),
          Text(
            '콘텐츠가 비어있어요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI에게 슬라이드 내용을 생성해 달라고 요청하거나\n직접 핵심 문장을 입력해보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

extension on BoxShape {
  Decoration asDecoration({required Color color}) {
    return BoxDecoration(shape: this, color: color);
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.elements});

  final List<SlideElement> elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < elements.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxShape.circle
                      .asDecoration(color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    elements[i].data['text']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
            if (i != elements.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock({required this.elements});

  final List<SlideElement> elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < elements.length; i++) ...[
            Text(
              elements[i].data['text']?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    height: 1.6,
                  ),
            ),
            if (i != elements.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SupplementaryElementPanel extends StatelessWidget {
  const _SupplementaryElementPanel({
    required this.chartElements,
    required this.tableElements,
    required this.iconElements,
    required this.shapeElements,
    required this.videoElements,
    required this.animationElements,
  });

  final List<SlideElement> chartElements;
  final List<SlideElement> tableElements;
  final List<SlideElement> iconElements;
  final List<SlideElement> shapeElements;
  final List<SlideElement> videoElements;
  final List<SlideElement> animationElements;

  @override
  Widget build(BuildContext context) {
    final groups = <_SupplementaryGroup>[
      _SupplementaryGroup(
        icon: Icons.insert_chart_outlined,
        label: '차트',
        description: '데이터 시각화',
        elements: chartElements,
      ),
      _SupplementaryGroup(
        icon: Icons.table_chart_outlined,
        label: '표',
        description: '데이터 표/시트',
        elements: tableElements,
      ),
      _SupplementaryGroup(
        icon: Icons.emoji_objects_outlined,
        label: '아이콘',
        description: '강조용 그래픽',
        elements: iconElements,
      ),
      _SupplementaryGroup(
        icon: Icons.category_outlined,
        label: '도형',
        description: '도형 및 배경 요소',
        elements: shapeElements,
      ),
      _SupplementaryGroup(
        icon: Icons.videocam_outlined,
        label: '비디오',
        description: '슬라이드 내 영상',
        elements: videoElements,
      ),
      _SupplementaryGroup(
        icon: Icons.motion_photos_auto_outlined,
        label: '애니메이션',
        description: '애니메이션/트랜지션',
        elements: animationElements,
      ),
    ].where((group) => group.elements.isNotEmpty).toList();

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.widgets_outlined,
                  size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '추가 콘텐츠',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final group in groups) _SupplementaryCard(group: group),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplementaryCard extends StatelessWidget {
  const _SupplementaryCard({required this.group});

  final _SupplementaryGroup group;

  @override
  Widget build(BuildContext context) {
    final primaryText = _primaryText(group.elements.first);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${group.elements.length}개 요소',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            primaryText.isEmpty ? group.description : primaryText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  String _primaryText(SlideElement element) {
    final data = element.data;
    final candidates = [
      data['title'],
      data['label'],
      data['text'],
      data['description'],
      data['type'],
    ];
    return candidates
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }
}

class _SupplementaryGroup {
  const _SupplementaryGroup({
    required this.icon,
    required this.label,
    required this.description,
    required this.elements,
  });

  final IconData icon;
  final String label;
  final String description;
  final List<SlideElement> elements;
}
