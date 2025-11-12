import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/project.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/project_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/login_required_dialog.dart';
import '../editor/editor_page.dart';

/// 홈 페이지 - 프로젝트 목록 및 새 프로젝트 생성
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  /// 프로젝트 목록 로드
  Future<void> _loadProjects() async {
    try {
      // Firebase에서 프로젝트 로드 (Provider가 자동으로 처리)
      // 샘플 데이터는 Firebase에 직접 추가하지 않음
    } catch (e) {
      _showErrorSnackBar('프로젝트를 불러오는 데 실패했습니다: $e');
    }
  }

  /// 새 프로젝트 생성 다이얼로그
  Future<void> _showCreateProjectDialog() async {
    // 인증 상태 확인
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final isAnonymous = ref.read(isAnonymousUserProvider);

    // 익명 사용자이거나 로그인하지 않은 경우
    if (!isAuthenticated || isAnonymous) {
      final promptResult = await LoginRequiredDialog.show(context);

      if (promptResult == LoginPromptResult.cancel) {
        return; // 사용자가 취소함
      }

      if (promptResult == LoginPromptResult.login) {
        try {
          await _handleGoogleLogin();
          // 로그인 성공 시 상태 새로고침
          await Future.delayed(const Duration(milliseconds: 500));
          final newAuthState = ref.read(isAuthenticatedProvider);
          if (!newAuthState) {
            print('⚠️ Google 로그인 실패, 임시 모드로 진행');
          }
        } catch (e) {
          // 로그인 실패해도 임시 모드로 계속 진행
          print('⚠️ Google 로그인 실패, 임시 모드로 진행: $e');
          if (mounted) {
            _showErrorSnackBar(
              'Google 로그인에 실패했습니다.\n'
              '임시 모드로 프로젝트를 생성합니다.\n'
              '(로컬에만 저장됩니다)',
            );
          }
        }
      }
      // LoginPromptResult.temporary 인 경우 로그인 시도 없이 계속 진행
    }

    // 프로젝트 생성 다이얼로그 표시
    if (!mounted) return;
    final request = await showDialog<CreateProjectRequest>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const CreateProjectWizard(),
    );

    if (request != null) {
      await _createProject(request);
    }
  }

  /// Google 로그인 처리
  Future<void> _handleGoogleLogin() async {
    if (!mounted) return;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showSuccessSnackBar('Google 로그인에 성공했습니다!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        final errorMessage = e.toString();

        // 오류 메시지 표시 (하지만 계속 진행 가능)
        if (errorMessage.contains('NetworkError') ||
            errorMessage.contains('unknown_reason') ||
            errorMessage.contains('popup_closed') ||
            errorMessage.contains('400')) {
          // 조용히 실패 처리 (임시 모드로 계속 진행)
          print('⚠️ Google 로그인 실패, 임시 모드로 진행');
        } else if (!errorMessage.contains('취소')) {
          _showErrorSnackBar('Google 로그인에 실패했습니다. 임시 모드로 진행합니다.');
        }
      }
      rethrow; // 호출한 곳에서 처리하도록
    }
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) {
        _showSuccessSnackBar('로그아웃되었습니다');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('로그아웃에 실패했습니다: $e');
      }
    }
  }

  /// 새 프로젝트 생성
  Future<void> _createProject(CreateProjectRequest request) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final project = await ref
          .read(projectCreationProvider.notifier)
          .createProjectWithSlides(
            title: request.title,
            slideOutlines: request.slideOutlines,
          );

      navigator.pop();
      if (!mounted) return;

      _showSuccessSnackBar('슬라이드 생성이 완료되었습니다');

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (editorContext) => EditorPage(projectId: project.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        navigator.pop();
        _showErrorSnackBar('프로젝트 생성에 실패했습니다: $e');
      }
    }
  }

  /// 프로젝트 삭제
  Future<void> _deleteProject(LectureProject project) async {
    final confirmed = await _showDeleteConfirmDialog(project.title);
    if (!confirmed) return;

    try {
      ref.read(projectListProvider.notifier).removeProject(project.id);

      // 현재 선택된 프로젝트라면 해제
      final currentProject = ref.read(currentProjectProvider);
      if (currentProject?.id == project.id) {
        ref.read(currentProjectProvider.notifier).clearProject();
      }

      _showSuccessSnackBar('프로젝트가 삭제되었습니다');
    } catch (e) {
      _showErrorSnackBar('프로젝트 삭제에 실패했습니다: $e');
    }
  }

  /// 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog(String projectTitle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 삭제'),
        content: Text('\'$projectTitle\' 프로젝트를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 필터링된 프로젝트 목록
  Widget get _filteredProjects {
    final projectsAsync = ref.watch(projectListProvider);

    return projectsAsync.when(
      data: (projects) {
        if (_searchQuery.isEmpty) {
          return _buildProjectGrid(projects);
        } else {
          // 검색 결과를 비동기로 처리
          return FutureBuilder<List<LectureProject>>(
            future: ref
                .read(projectListProvider.notifier)
                .searchProjects(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildProjectGrid(snapshot.data!);
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('검색 중 오류가 발생했습니다: ${snapshot.error}'),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('프로젝트를 불러오는 중 오류가 발생했습니다: $error')),
    );
  }

  /// 프로젝트 그리드 빌드
  Widget _buildProjectGrid(List<LectureProject> projects) {
    if (projects.isEmpty) {
      return EmptyState(
        title: _searchQuery.isEmpty ? '프로젝트가 없습니다' : '검색 결과가 없습니다',
        subtitle: _searchQuery.isEmpty
            ? '새 프로젝트를 생성하여 강의 영상 제작을 시작하세요'
            : '다른 검색어를 시도해보세요',
        icon: _searchQuery.isEmpty
            ? Icons.video_library_outlined
            : Icons.search_off,
        actionText: _searchQuery.isEmpty ? '새 프로젝트 생성' : null,
        onAction: _searchQuery.isEmpty ? _showCreateProjectDialog : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 실제 저장소에서 새로고침
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.2,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ProjectCard(
            project: project,
            onTap: () {
              // 에디터 페이지로 이동
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditorPage(projectId: project.id),
                ),
              );
            },
            onEdit: () {
              // TODO: 프로젝트 편집
              _showSuccessSnackBar('프로젝트 편집 기능은 준비중입니다');
            },
            onDelete: () => _deleteProject(project),
            onDuplicate: () {
              // TODO: 프로젝트 복제
              _showSuccessSnackBar('프로젝트 복제 기능은 준비중입니다');
            },
          );
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.success),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isAnonymous = ref.watch(isAnonymousUserProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        subtitle: '강의 영상 제작 플랫폼',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () {
              // TODO: 설정 페이지로 이동
            },
          ),
          if (isAuthenticated && !isAnonymous) ...[
            if (currentUser?.email != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  currentUser!.email!,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '로그아웃',
              onPressed: _handleLogout,
            ),
          ] else
            TextButton.icon(
              onPressed: _handleGoogleLogin,
              icon: const Icon(Icons.login),
              label: const Text('로그인'),
            ),
        ],
      ),

      body: Column(
        children: [
          // 상단 액션 바
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // 검색
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '프로젝트 검색...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // 새 프로젝트 버튼
                ElevatedButton.icon(
                  onPressed: _showCreateProjectDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('새 프로젝트'),
                ),
              ],
            ),
          ),

          // 프로젝트 목록
          Expanded(child: _filteredProjects),
        ],
      ),

      // 플로팅 액션 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '새 프로젝트',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 프로젝트 생성 요청 데이터
class CreateProjectRequest {
  CreateProjectRequest({required this.title, required this.slideOutlines});

  final String title;
  final List<String> slideOutlines;
}

/// 새 프로젝트 생성 위자드
class CreateProjectWizard extends StatefulWidget {
  const CreateProjectWizard({super.key});

  @override
  State<CreateProjectWizard> createState() => _CreateProjectWizardState();
}

class _CreateProjectWizardState extends State<CreateProjectWizard> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<TextEditingController> _outlineControllers = [];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _outlineControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _outlineControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOutlineField() {
    setState(() {
      _outlineControllers.add(TextEditingController());
    });
  }

  void _removeOutlineField(int index) {
    if (_outlineControllers.length == 1) return;
    setState(() {
      final controller = _outlineControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final outlines = _outlineControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (outlines.isEmpty) {
      setState(() {
        _errorText = '최소 한 개의 슬라이드 개요를 입력해 주세요.';
      });
      return;
    }

    Navigator.of(context).pop(
      CreateProjectRequest(
        title: _titleController.text.trim(),
        slideOutlines: outlines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '새 프로젝트 생성',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '프로젝트 제목과 슬라이드 개요를 입력하면 AI가 자동으로 슬라이드를 작성합니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '프로젝트 제목',
                          hintText: '예: 생성형 AI 입문 강의',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '프로젝트 제목을 입력해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '슬라이드 개요',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '각 입력 칸이 하나의 슬라이드가 됩니다. 중요한 포인트를 간략히 적어 주세요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (
                        int index = 0;
                        index < _outlineControllers.length;
                        index++
                      )
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _outlineControllers[index],
                                  decoration: InputDecoration(
                                    labelText: '슬라이드 ${index + 1} 개요',
                                    hintText: '이 슬라이드에서 다룰 핵심 내용을 입력하세요.',
                                  ),
                                  minLines: 2,
                                  maxLines: 4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_outlineControllers.length > 1)
                                IconButton(
                                  tooltip: '이 개요 삭제',
                                  onPressed: () => _removeOutlineField(index),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                            ],
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _addOutlineField,
                        icon: const Icon(Icons.add),
                        label: const Text('슬라이드 추가'),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('프로젝트 생성'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
