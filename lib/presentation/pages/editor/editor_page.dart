import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/project.dart';
import '../../../data/models/slide.dart';
import '../../providers/project_provider.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/slide_editor_tab.dart';
import 'widgets/avatar_editor_tab.dart';
import 'widgets/slide_list_panel.dart';

/// 에디터 페이지
class EditorPage extends ConsumerStatefulWidget {
  final String projectId;

  const EditorPage({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectStream = ref.watch(projectByIdProvider(widget.projectId));
    
    return projectStream.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('프로젝트를 찾을 수 없습니다'),
            ),
            body: const Center(
              child: Text('프로젝트를 찾을 수 없습니다'),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: EditorAppBar(
            project: project,
            onSave: () => _saveProject(project),
            onExport: () => _exportProject(project),
            onBack: () => Navigator.of(context).pop(),
          ),
          body: Column(
            children: [
              // 탭 헤더
              Container(
                color: AppTheme.surfaceColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.slideshow),
                      text: '슬라이드',
                    ),
                    Tab(
                      icon: Icon(Icons.face),
                      text: '아바타',
                    ),
                  ],
                ),
              ),
              // 탭 내용
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SlideEditorTab(
                      project: project,
                      selectedSlideIndex: _selectedSlideIndex,
                      onSlideSelected: (index) {
                        setState(() {
                          _selectedSlideIndex = index;
                        });
                      },
                      onSlideChanged: (updatedSlide) =>
                          _updateSlide(project, updatedSlide),
                      onSlidesGenerated: (slides) =>
                          _appendGeneratedSlides(project, slides),
                    ),
                    AvatarEditorTab(
                      project: project,
                      selectedSlideIndex: _selectedSlideIndex,
                      onSlideSelected: (index) {
                        setState(() {
                          _selectedSlideIndex = index;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // 슬라이드 목록 패널 (공용)
              SlideListPanel(
                project: project,
                selectedSlideIndex: _selectedSlideIndex,
                onSlideSelected: (index) {
                  setState(() {
                    _selectedSlideIndex = index;
                  });
                },
                onSlideAdded: () => _addSlide(project),
                onSlideDeleted: (index) => _deleteSlide(project, index),
                onSlideReordered: (oldIndex, newIndex) => 
                    _reorderSlides(project, oldIndex, newIndex),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('오류'),
        ),
        body: Center(
          child: Text('프로젝트를 불러오는 중 오류가 발생했습니다: $error'),
        ),
      ),
    );
  }

  void _saveProject(LectureProject project) {
    ref.read(projectListProvider.notifier).updateProject(project);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로젝트가 저장되었습니다')),
    );
  }

  void _exportProject(LectureProject project) {
    // TODO: 내보내기 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('내보내기 기능은 준비 중입니다')),
    );
  }

  List<SlideData> _normalizeSlideOrder(List<SlideData> slides) {
    return [
      for (var i = 0; i < slides.length; i++) slides[i].copyWith(order: i),
    ];
  }

  Future<void> _addSlide(LectureProject project) async {
    final newIndex = project.slides.length;
    final newSlide = SlideData.create(
      title: '새 슬라이드 ${newIndex + 1}',
      order: newIndex,
    );
    final updatedSlides = _normalizeSlideOrder([
      ...project.slides,
      newSlide,
    ]);
    final updatedProject = project.copyWith(slides: updatedSlides);

    try {
      await ref.read(projectListProvider.notifier).updateProject(updatedProject);
      ref.read(currentProjectProvider.notifier).updateProject(updatedProject);
      if (mounted) {
        setState(() {
          _selectedSlideIndex = updatedSlides.length - 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('슬라이드가 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('슬라이드를 추가하지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteSlide(LectureProject project, int index) async {
    if (project.slides.isEmpty || index < 0 || index >= project.slides.length) {
      return;
    }

    final updatedSlides = List<SlideData>.from(project.slides)..removeAt(index);
    final normalizedSlides = _normalizeSlideOrder(updatedSlides);
    final updatedProject = project.copyWith(slides: normalizedSlides);

    try {
      await ref.read(projectListProvider.notifier).updateProject(updatedProject);
      ref.read(currentProjectProvider.notifier).updateProject(updatedProject);
      if (mounted) {
        setState(() {
          if (normalizedSlides.isEmpty) {
            _selectedSlideIndex = 0;
          } else {
            _selectedSlideIndex =
                index.clamp(0, normalizedSlides.length - 1);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('슬라이드가 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('슬라이드를 삭제하지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _updateSlide(
    LectureProject project,
    SlideData updatedSlide,
  ) async {
    final updatedSlides = project.slides
        .map((slide) => slide.id == updatedSlide.id ? updatedSlide : slide)
        .toList();

    final updatedProject = project.copyWith(slides: updatedSlides);

    try {
      await ref.read(projectListProvider.notifier).updateProject(updatedProject);
      ref.read(currentProjectProvider.notifier).updateProject(updatedProject);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('슬라이드를 업데이트하지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _reorderSlides(
    LectureProject project,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= project.slides.length ||
        newIndex < 0 ||
        newIndex >= project.slides.length) {
      return;
    }

    final slides = List<SlideData>.from(project.slides);
    final movedSlide = slides.removeAt(oldIndex);
    slides.insert(newIndex, movedSlide);
    final normalizedSlides = _normalizeSlideOrder(slides);
    final updatedProject = project.copyWith(slides: normalizedSlides);

    try {
      await ref.read(projectListProvider.notifier).updateProject(updatedProject);
      ref.read(currentProjectProvider.notifier).updateProject(updatedProject);
      if (mounted) {
        setState(() {
          if (_selectedSlideIndex == oldIndex) {
            _selectedSlideIndex = newIndex;
          } else if (oldIndex < _selectedSlideIndex &&
              newIndex >= _selectedSlideIndex) {
            _selectedSlideIndex -= 1;
          } else if (oldIndex > _selectedSlideIndex &&
              newIndex <= _selectedSlideIndex) {
            _selectedSlideIndex += 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('슬라이드 순서를 변경하지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _appendGeneratedSlides(
    LectureProject project,
    List<SlideData> generatedSlides,
  ) async {
    if (generatedSlides.isEmpty) {
      return;
    }

    final baseOrder = project.slides.length;
    final adjustedSlides = <SlideData>[];

    for (var i = 0; i < generatedSlides.length; i++) {
      adjustedSlides.add(
        generatedSlides[i].copyWith(order: baseOrder + i),
      );
    }

    final updatedSlides = _normalizeSlideOrder([
      ...project.slides,
      ...adjustedSlides,
    ]);

    final updatedProject = project.copyWith(slides: updatedSlides);

    try {
      await ref.read(projectListProvider.notifier).updateProject(updatedProject);
      ref.read(currentProjectProvider.notifier).updateProject(updatedProject);

      if (mounted) {
        setState(() {
          _selectedSlideIndex =
              updatedSlides.length - adjustedSlides.length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI 슬라이드 ${adjustedSlides.length}개가 추가되었습니다',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 슬라이드를 추가하지 못했습니다: $e'),
          ),
        );
      }
    }
  }
}