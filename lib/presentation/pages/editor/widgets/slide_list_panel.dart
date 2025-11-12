import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 슬라이드 목록 패널 (좌측 사이드)
class SlideListPanel extends StatelessWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<int> onSlideSelected;
  final VoidCallback onSlideAdded;
  final ValueChanged<int> onSlideDeleted;
  final void Function(int oldIndex, int newIndex) onSlideReordered;

  const SlideListPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlideSelected,
    required this.onSlideAdded,
    required this.onSlideDeleted,
    required this.onSlideReordered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          right: BorderSide(color: AppTheme.borderColor.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 12,
              top: 20,
              bottom: 12,
            ),
            child: Row(
              children: [
                Text(
                  '슬라이드',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onSlideAdded,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('추가'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: project.slides.isEmpty
                  ? _EmptyListPlaceholder(onAdd: onSlideAdded)
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: project.slides.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        onSlideReordered(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final slide = project.slides[index];
                        final isSelected = index == selectedSlideIndex;
                        return Container(
                          key: ValueKey(slide.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.18)
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onSlideSelected(index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.drag_indicator,
                                          size: 20,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.borderColor,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTheme.titleMedium.copyWith(
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slide.title.isEmpty
                                                ? '제목 없는 슬라이드'
                                                : slide.title,
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.textPrimaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${slide.elements.length}개의 요소',
                                            style: AppTheme.bodySmall.copyWith(
                                              color:
                                                  AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: '슬라이드 삭제',
                                      onPressed: () => onSlideDeleted(index),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyListPlaceholder extends StatelessWidget {
  const _EmptyListPlaceholder({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.slideshow_outlined,
            size: 36,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            '슬라이드가 없습니다',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '오른쪽 상단의 추가 버튼을 눌러 새로운 슬라이드를 만들어보세요.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('슬라이드 추가'),
          ),
        ],
      ),
    );
  }
}
