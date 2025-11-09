import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/slide.dart';
import '../../data/models/project.dart';

part 'slide_editor_provider.g.dart';

/// 슬라이드 편집 상태 관리
@riverpod
class SlideEditor extends _$SlideEditor {
  @override
  SlideEditorState build() {
    return const SlideEditorState.idle();
  }

  /// 슬라이드 편집 시작
  void startEditing(LectureProject project) {
    state = SlideEditorState.editing(
      project: project,
      selectedSlideIndex: 0,
      selectedElementId: null,
    );
  }

  /// 슬라이드 선택
  void selectSlide(int slideIndex) {
    final currentState = state;
    if (currentState is _Editing) {
      state = currentState.copyWith(selectedSlideIndex: slideIndex);
    }
  }

  /// 슬라이드 요소 선택
  void selectElement(String? elementId) {
    final currentState = state;
    if (currentState is _Editing) {
      state = currentState.copyWith(selectedElementId: elementId);
    }
  }

  /// 슬라이드 추가
  void addSlide() {
    final currentState = state;
    if (currentState is _Editing) {
      final newSlide = SlideData.create(
        title: '새 슬라이드',
        order: currentState.project.slides.length,
      );
      
      final updatedProject = currentState.project.copyWith(
        slides: [...currentState.project.slides, newSlide],
      );
      
      state = currentState.copyWith(
        project: updatedProject,
        selectedSlideIndex: currentState.project.slides.length,
      );
    }
  }

  /// 슬라이드 삭제
  void deleteSlide(int slideIndex) {
    final currentState = state;
    if (currentState is _Editing && currentState.project.slides.length > 1) {
      final updatedSlides = List<SlideData>.from(currentState.project.slides);
      updatedSlides.removeAt(slideIndex);
      
      // 순서 재정렬
      for (int i = 0; i < updatedSlides.length; i++) {
        updatedSlides[i] = updatedSlides[i].copyWith(order: i);
      }
      
      final updatedProject = currentState.project.copyWith(slides: updatedSlides);
      
      state = currentState.copyWith(
        project: updatedProject,
        selectedSlideIndex: slideIndex >= updatedSlides.length 
            ? updatedSlides.length - 1 
            : slideIndex,
      );
    }
  }

  /// 슬라이드 순서 변경
  void reorderSlides(int oldIndex, int newIndex) {
    final currentState = state;
    if (currentState is _Editing) {
      final updatedSlides = List<SlideData>.from(currentState.project.slides);
      final slide = updatedSlides.removeAt(oldIndex);
      updatedSlides.insert(newIndex, slide);
      
      // 순서 재정렬
      for (int i = 0; i < updatedSlides.length; i++) {
        updatedSlides[i] = updatedSlides[i].copyWith(order: i);
      }
      
      final updatedProject = currentState.project.copyWith(slides: updatedSlides);
      
      state = currentState.copyWith(
        project: updatedProject,
        selectedSlideIndex: newIndex,
      );
    }
  }

  /// 슬라이드 업데이트
  void updateSlide(int slideIndex, SlideData updatedSlide) {
    final currentState = state;
    if (currentState is _Editing) {
      final updatedSlides = List<SlideData>.from(currentState.project.slides);
      updatedSlides[slideIndex] = updatedSlide;
      
      final updatedProject = currentState.project.copyWith(slides: updatedSlides);
      
      state = currentState.copyWith(project: updatedProject);
    }
  }

  /// 슬라이드 요소 추가
  void addElement(int slideIndex, SlideElement element) {
    final currentState = state;
    if (currentState is _Editing) {
      final slide = currentState.project.slides[slideIndex];
      final updatedSlide = slide.addElement(element);
      updateSlide(slideIndex, updatedSlide);
    }
  }

  /// 슬라이드 요소 업데이트
  void updateElement(int slideIndex, String elementId, SlideElement updatedElement) {
    final currentState = state;
    if (currentState is _Editing) {
      final slide = currentState.project.slides[slideIndex];
      final updatedSlide = slide.updateElement(elementId, updatedElement);
      updateSlide(slideIndex, updatedSlide);
    }
  }

  /// 슬라이드 요소 삭제
  void removeElement(int slideIndex, String elementId) {
    final currentState = state;
    if (currentState is _Editing) {
      final slide = currentState.project.slides[slideIndex];
      final updatedSlide = slide.removeElement(elementId);
      updateSlide(slideIndex, updatedSlide);
    }
  }

  /// 편집 종료
  void stopEditing() {
    state = const SlideEditorState.idle();
  }
}

/// 슬라이드 편집 상태
sealed class SlideEditorState {
  const SlideEditorState();
  
  const factory SlideEditorState.idle() = _Idle;
  const factory SlideEditorState.editing({
    required LectureProject project,
    required int selectedSlideIndex,
    String? selectedElementId,
  }) = _Editing;
}

class _Idle extends SlideEditorState {
  const _Idle();
}

class _Editing extends SlideEditorState {
  const _Editing({
    required this.project,
    required this.selectedSlideIndex,
    this.selectedElementId,
  });
  
  final LectureProject project;
  final int selectedSlideIndex;
  final String? selectedElementId;
  
  _Editing copyWith({
    LectureProject? project,
    int? selectedSlideIndex,
    String? selectedElementId,
  }) {
    return _Editing(
      project: project ?? this.project,
      selectedSlideIndex: selectedSlideIndex ?? this.selectedSlideIndex,
      selectedElementId: selectedElementId ?? this.selectedElementId,
    );
  }
  
  /// 현재 선택된 슬라이드
  SlideData? get selectedSlide {
    if (selectedSlideIndex >= 0 && selectedSlideIndex < project.slides.length) {
      return project.slides[selectedSlideIndex];
    }
    return null;
  }
  
  /// 현재 선택된 요소
  SlideElement? get selectedElement {
    final slide = selectedSlide;
    if (slide != null && selectedElementId != null) {
      try {
        return slide.elements.firstWhere((element) => element.id == selectedElementId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}





