import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/project.dart';
import '../../core/constants/app_constants.dart';
import '../../services/ai/slide_ai_service.dart';
import 'firebase_providers.dart';

part 'project_provider.g.dart';

/// 프로젝트 목록 상태 관리 (Firebase 연동)
@riverpod
class ProjectList extends _$ProjectList {
  @override
  Future<List<LectureProject>> build() async {
    final userId = ref.watch(effectiveUserIdProvider);
    
    final repository = ref.watch(projectRepositoryProvider);
    return repository.watchProjects(userId).first;
  }

  /// 프로젝트 추가
  Future<void> addProject(LectureProject project) async {
    final userId = ref.watch(effectiveUserIdProvider);
    
    try {
      final repository = ref.watch(projectRepositoryProvider);
      await repository.createProject(userId, project);
      print('✅ 프로젝트 저장 성공: ${project.id} (사용자: $userId)');
      
      // 상태 새로고침
      ref.invalidateSelf();
    } catch (e) {
      print('❌ 프로젝트 저장 실패: $e');
      rethrow;
    }
  }

  /// 프로젝트 업데이트
  Future<void> updateProject(LectureProject updatedProject) async {
    final userId = ref.watch(effectiveUserIdProvider);
    
    try {
      final repository = ref.watch(projectRepositoryProvider);
      await repository.updateProject(userId, updatedProject);
      print('✅ 프로젝트 업데이트 성공: ${updatedProject.id} (사용자: $userId)');
      
      // 상태 새로고침
      ref.invalidateSelf();
    } catch (e) {
      print('❌ 프로젝트 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 프로젝트 삭제
  Future<void> removeProject(String projectId) async {
    final userId = ref.watch(effectiveUserIdProvider);
    
    final repository = ref.watch(projectRepositoryProvider);
    await repository.deleteProject(userId, projectId);
    
    // 상태 새로고침
    ref.invalidateSelf();
  }

  /// 프로젝트 검색
  Future<List<LectureProject>> searchProjects(String query) async {
    final userId = ref.watch(effectiveUserIdProvider);
    
    final repository = ref.watch(projectRepositoryProvider);
    return repository.searchProjects(userId, query);
  }
}

/// 현재 선택된 프로젝트 상태 관리
@riverpod
class CurrentProject extends _$CurrentProject {
  @override
  LectureProject? build() {
    return null;
  }

  /// 프로젝트 선택
  void selectProject(LectureProject project) {
    state = project;
  }

  /// 프로젝트 해제
  void clearProject() {
    state = null;
  }

  /// 프로젝트 업데이트
  void updateProject(LectureProject updatedProject) {
    state = updatedProject;
  }
}

/// 프로젝트 ID로 단일 프로젝트 로드
@riverpod
Stream<LectureProject?> projectById(ProjectByIdRef ref, String projectId) async* {
  final userId = ref.watch(effectiveUserIdProvider);
  
  final repository = ref.watch(projectRepositoryProvider);
  yield* repository.watchProject(userId, projectId);
}

/// 프로젝트 생성 상태 관리
@riverpod
class ProjectCreation extends _$ProjectCreation {
  @override
  ProjectCreationState build() {
    return const ProjectCreationState.idle();
  }

  /// 새 프로젝트 생성
  Future<void> createProject({
    required String title,
    required String overview,
    String? detailedOutline,
    Map<String, dynamic>? preferences,
    String? scriptContent,
  }) async {
    state = const ProjectCreationState.loading();
    
    try {
      final metadata = {
        if (preferences != null) ...preferences,
        if (detailedOutline != null && detailedOutline.isNotEmpty)
          'detailed_outline': detailedOutline,
      };

      final project = LectureProject.create(
        title: title,
        description: overview,
        scriptContent: scriptContent,
        extraMetadata: metadata.isEmpty ? null : metadata,
      );
      
      // 프로젝트 목록에 추가
      ref.read(projectListProvider.notifier).addProject(project);
      
      // 현재 프로젝트로 선택
      ref.read(currentProjectProvider.notifier).selectProject(project);
      
      state = ProjectCreationState.success(project);
    } catch (e) {
      state = ProjectCreationState.error(e.toString());
    }
  }

  /// AI 슬라이드 생성
  Future<void> generateSlides({
    required LectureProject project,
    required TemplateCategory category,
    int maxSlides = 10,
  }) async {
    state = const ProjectCreationState.generating();
    
    try {
      final slides = await SlideAIService.generateSlidesFromScript(
        script: project.script,
        category: category,
        maxSlides: maxSlides,
      );
      
      final updatedProject = project.copyWith(slides: slides);
      
      // 프로젝트 업데이트
      ref.read(projectListProvider.notifier).updateProject(updatedProject);
      ref.read(currentProjectProvider.notifier).updateProject(updatedProject);
      
      state = ProjectCreationState.slidesGenerated(updatedProject);
    } catch (e) {
      state = ProjectCreationState.error(e.toString());
    }
  }

  /// 상태 초기화
  void reset() {
    state = const ProjectCreationState.idle();
  }
}

/// 프로젝트 생성 상태
sealed class ProjectCreationState {
  const ProjectCreationState();
  
  const factory ProjectCreationState.idle() = _Idle;
  const factory ProjectCreationState.loading() = _Loading;
  const factory ProjectCreationState.generating() = _Generating;
  const factory ProjectCreationState.success(LectureProject project) = _Success;
  const factory ProjectCreationState.slidesGenerated(LectureProject project) = _SlidesGenerated;
  const factory ProjectCreationState.error(String message) = _Error;
}

class _Idle extends ProjectCreationState {
  const _Idle();
}

class _Loading extends ProjectCreationState {
  const _Loading();
}

class _Generating extends ProjectCreationState {
  const _Generating();
}

class _Success extends ProjectCreationState {
  const _Success(this.project);
  final LectureProject project;
}

class _SlidesGenerated extends ProjectCreationState {
  const _SlidesGenerated(this.project);
  final LectureProject project;
}

class _Error extends ProjectCreationState {
  const _Error(this.message);
  final String message;
}
