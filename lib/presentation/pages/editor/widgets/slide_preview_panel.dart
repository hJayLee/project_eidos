import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart';
import 'editable_slide_canvas.dart';

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
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 28,
                  offset: Offset(0, 18),
                  spreadRadius: -12,
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: EditableSlideCanvas(
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
  });

  final String title;
  final int slideNumber;
  final int totalSlides;

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
      child: Row(
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
              Icon(
                Icons.slideshow_outlined,
                size: 64,
                color: AppTheme.textSecondaryColor,
              ),
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