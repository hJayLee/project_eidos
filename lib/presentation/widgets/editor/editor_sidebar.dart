import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/project.dart';

/// 에디터 사이드바
class EditorSidebar extends StatelessWidget {
  final LectureProject project;
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final VoidCallback onGenerateSlides;
  final bool isGenerating;

  const EditorSidebar({
    super.key,
    required this.project,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.onGenerateSlides,
    this.isGenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = project.stats;

    return Column(
      children: [
        // 프로젝트 정보
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '프로젝트 개요',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // 진행률
              Row(
                children: [
                  Icon(
                    Icons.trending_up_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '진행률 ${(stats.completionPercentage * 100).toInt()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stats.completionPercentage,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              
              const SizedBox(height: 16),
              
              // 통계
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.slideshow_outlined,
                      '${stats.totalSlides}',
                      '슬라이드',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.access_time_outlined,
                      stats.formattedDuration,
                      '예상 시간',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Divider(
          color: theme.dividerColor.withValues(alpha: 0.1),
          height: 1,
        ),

        // 탭 메뉴
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildTabItem(
                context,
                icon: Icons.edit_note_outlined,
                title: '스크립트',
                subtitle: '강의 대본 작성',
                index: 0,
                badge: stats.scriptWordCount > 0 ? '${stats.scriptWordCount}단어' : null,
              ),
              
              _buildTabItem(
                context,
                icon: Icons.slideshow_outlined,
                title: '슬라이드',
                subtitle: '슬라이드 편집',
                index: 1,
                badge: stats.totalSlides > 0 ? '${stats.totalSlides}개' : null,
              ),
              
              _buildTabItem(
                context,
                icon: Icons.person_outline,
                title: '아바타',
                subtitle: '가상 강연자',
                index: 2,
                isDisabled: true,
              ),
              
              _buildTabItem(
                context,
                icon: Icons.play_circle_outline,
                title: '미리보기',
                subtitle: '영상 확인',
                index: 3,
                isDisabled: true,
              ),
            ],
          ),
        ),

        Divider(
          color: theme.dividerColor.withValues(alpha: 0.1),
          height: 1,
        ),

        // 액션 버튼들
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // AI 슬라이드 생성 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isGenerating ? null : onGenerateSlides,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    isGenerating ? '생성 중...' : 'AI 슬라이드 생성',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 저장 기능
                  },
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    String? badge,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedTabIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isDisabled ? null : () => onTabChanged(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDisabled
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                              : isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDisabled
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                
                if (isDisabled) ...[
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}








