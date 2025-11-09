import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/slide.dart';
import '../../widgets/common/empty_state.dart';

/// 슬라이드 미리보기 위젯
class SlidePreview extends StatefulWidget {
  final List<SlideData> slides;
  final Function(SlideData) onSlideUpdated;

  const SlidePreview({
    super.key,
    required this.slides,
    required this.onSlideUpdated,
  });

  @override
  State<SlidePreview> createState() => _SlidePreviewState();
}

class _SlidePreviewState extends State<SlidePreview> {
  int _selectedSlideIndex = 0;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.slides.isEmpty) {
      return EmptyState(
        title: '슬라이드가 없습니다',
        subtitle: '스크립트를 작성하고 AI 슬라이드 생성을 클릭하여\n자동으로 슬라이드를 만들어보세요',
        icon: Icons.slideshow_outlined,
        actionText: '스크립트 작성하기',
        onAction: () {
          // TODO: 스크립트 탭으로 이동
        },
      );
    }

    return Column(
      children: [
        // 상단 툴바
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '슬라이드 미리보기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.slides.length}개',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // 보기 모드 토글
              ToggleButtons(
                isSelected: [!_isGridView, _isGridView],
                onPressed: (index) {
                  setState(() {
                    _isGridView = index == 1;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.view_agenda_outlined, size: 18),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.grid_view_outlined, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 메인 콘텐츠
        Expanded(
          child: _isGridView ? _buildGridView() : _buildSingleView(),
        ),
      ],
    );
  }

  Widget _buildSingleView() {
    final theme = Theme.of(context);
    final currentSlide = widget.slides[_selectedSlideIndex];

    return Row(
      children: [
        // 왼쪽 슬라이드 리스트
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              // 슬라이드 리스트 헤더
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '슬라이드 목록',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: '슬라이드 추가',
                      onPressed: () {
                        // TODO: 슬라이드 추가 기능
                      },
                    ),
                  ],
                ),
              ),
              
              // 슬라이드 목록
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: widget.slides.length,
                  itemBuilder: (context, index) {
                    final slide = widget.slides[index];
                    final isSelected = index == _selectedSlideIndex;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSlideIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // 슬라이드 번호
                                Container(
                                  width: 32,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // 슬라이드 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slide.title.isEmpty ? '제목 없음' : slide.title,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${slide.elements.length}개 요소',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // 메뉴
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  onSelected: (value) {
                                    // TODO: 슬라이드 메뉴 액션
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('편집'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text('복제'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('삭제'),
                                    ),
                                  ],
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
            ],
          ),
        ),

        // 오른쪽 슬라이드 미리보기
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 슬라이드 정보
                Row(
                  children: [
                    Text(
                      '슬라이드 ${_selectedSlideIndex + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentSlide.title,
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '편집',
                      onPressed: () {
                        widget.onSlideUpdated(currentSlide);
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 슬라이드 미리보기 영역
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildSlideContent(currentSlide),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 네비게이션 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '이전 슬라이드',
                      onPressed: _selectedSlideIndex > 0
                          ? () {
                              setState(() {
                                _selectedSlideIndex--;
                              });
                            }
                          : null,
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedSlideIndex + 1} / ${widget.slides.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '다음 슬라이드',
                      onPressed: _selectedSlideIndex < widget.slides.length - 1
                          ? () {
                              setState(() {
                                _selectedSlideIndex++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 16 / 9,
      ),
      itemCount: widget.slides.length,
      itemBuilder: (context, index) {
        final slide = widget.slides[index];
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedSlideIndex = index;
              _isGridView = false;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: _buildSlideContent(slide),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slide.title.isEmpty ? '제목 없음' : slide.title,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlideContent(SlideData slide) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          // 배경
          if (slide.backgroundImagePath != null)
            Positioned.fill(
              child: Image.network(
                slide.backgroundImagePath!,
                fit: BoxFit.cover,
              ),
            ),
          
          // 요소들
          ...slide.elements.map((element) => _buildSlideElement(element)),
          
          // 제목 (요소가 없는 경우)
          if (slide.elements.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '슬라이드 콘텐츠가 없습니다',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlideElement(SlideElement element) {
    switch (element.type) {
      case SlideElementType.text:
        return Positioned(
          left: element.position.x,
          top: element.position.y,
          width: element.size.width,
          height: element.size.height,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              element.data['content']?.toString() ?? '',
              style: TextStyle(
                fontSize: element.style.fontSize ?? 16,
                fontWeight: element.style.fontWeight == 'bold'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: Color(int.parse(
                  (element.style.color ?? '#000000').replaceFirst('#', '0xFF'),
                )),
              ),
            ),
          ),
        );
      
      case SlideElementType.image:
        return Positioned(
          left: element.position.x,
          top: element.position.y,
          width: element.size.width,
          height: element.size.height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
      
      default:
        return Positioned(
          left: element.position.x,
          top: element.position.y,
          width: element.size.width,
          height: element.size.height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              border: Border.all(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                _getElementTypeName(element.type),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
    }
  }

  String _getElementTypeName(SlideElementType type) {
    switch (type) {
      case SlideElementType.text:
        return '텍스트';
      case SlideElementType.image:
        return '이미지';
      case SlideElementType.video:
        return '비디오';
      case SlideElementType.chart:
        return '차트';
      case SlideElementType.table:
        return '표';
      case SlideElementType.shape:
        return '도형';
      case SlideElementType.icon:
        return '아이콘';
      case SlideElementType.background:
        return '배경';
      case SlideElementType.animation:
        return '애니메이션';
    }
  }
}

