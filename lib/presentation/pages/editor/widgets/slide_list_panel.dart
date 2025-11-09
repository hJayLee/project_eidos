import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 슬라이드 목록 패널 (공용)
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
      height: 140,
      color: AppTheme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 패널 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '슬라이드 목록',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onSlideAdded,
                  color: AppTheme.primaryColor,
                  tooltip: '슬라이드 추가',
                ),
              ],
            ),
          ),
          // 슬라이드 목록
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: project.slides.isEmpty
                  ? Center(
                      child: Text(
                        '슬라이드가 없습니다. 추가해보세요!',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        onSlideReordered(oldIndex, newIndex);
                      },
                      itemCount: project.slides.length,
                      itemBuilder: (context, index) {
                        final slide = project.slides[index];
                        final isSelected = index == selectedSlideIndex;

                        return Container(
                          key: ValueKey(slide.id),
                          width: 96,
                          margin: const EdgeInsets.only(right: 12),
                          child: Material(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => onSlideSelected(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                children: [
                                  // 드래그 핸들
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 4, right: 4),
                                        child: Icon(
                                          Icons.drag_handle,
                                          size: 16,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 슬라이드 썸네일
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.borderColor,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: AppTheme.titleMedium.copyWith(
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 슬라이드 제목
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      slide.title,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // 삭제 버튼
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onPressed: () => onSlideDeleted(index),
                                    color: AppTheme.textSecondaryColor,
                                    tooltip: '슬라이드 삭제',
                                  ),
                                ],
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
