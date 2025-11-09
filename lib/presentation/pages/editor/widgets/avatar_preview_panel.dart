import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 아바타 영상 미리보기 패널
class AvatarPreviewPanel extends StatelessWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final VoidCallback onVideoGenerated;

  const AvatarPreviewPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onVideoGenerated,
  });

  @override
  Widget build(BuildContext context) {
    final slide = selectedSlideIndex < project.slides.length
        ? project.slides[selectedSlideIndex]
        : null;

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '아바타 영상 미리보기',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onVideoGenerated,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('영상 생성'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 영상 미리보기
          Expanded(
            child: Center(
              child: slide != null
                  ? _buildVideoPreview(slide)
                  : _buildEmptyState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(slide) {
    return Container(
      width: 600,
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아바타 영역
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.face,
              size: 80,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // 슬라이드 정보
          Text(
            slide.title,
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '아바타 영상 미리보기',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // 대본 미리보기
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              slide.speakerNotes ?? '대본이 없습니다',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 400,
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '아바타 영상이 없습니다',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '슬라이드를 선택하고\n아바타와 대본을 설정해보세요!',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





