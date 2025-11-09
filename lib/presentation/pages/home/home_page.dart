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
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
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
    try {
      await ref.read(projectCreationProvider.notifier).createProject(
        title: request.title,
        overview: request.overview,
        detailedOutline: request.detailedOutline,
        preferences: request.toMetadata(),
      );
      
      _showSuccessSnackBar('새 프로젝트가 생성되었습니다');
      
      // 에디터로 이동
      if (!mounted) return;
      final currentProject = ref.read(currentProjectProvider);
      if (currentProject != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (editorContext) => EditorPage(projectId: currentProject.id),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('프로젝트 생성에 실패했습니다: $e');
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
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
            future: ref.read(projectListProvider.notifier).searchProjects(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildProjectGrid(snapshot.data!);
              } else if (snapshot.hasError) {
                return Center(child: Text('검색 중 오류가 발생했습니다: ${snapshot.error}'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('프로젝트를 불러오는 중 오류가 발생했습니다: $error'),
      ),
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
        icon: _searchQuery.isEmpty ? Icons.video_library_outlined : Icons.search_off,
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
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
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
          Expanded(
            child: _filteredProjects,
          ),
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
  CreateProjectRequest({
    required this.title,
    required this.overview,
    this.detailedOutline,
    required this.targetAudience,
    required this.estimatedDuration,
    required this.toneOfVoice,
    required this.visualStyle,
    this.includeReferences = true,
    this.includeInteractiveElements = false,
  });

  final String title;
  final String overview;
  final String? detailedOutline;
  final String targetAudience;
  final String estimatedDuration;
  final String toneOfVoice;
  final String visualStyle;
  final bool includeReferences;
  final bool includeInteractiveElements;

  Map<String, dynamic> toMetadata() {
    return {
      'target_audience': targetAudience,
      'estimated_duration': estimatedDuration,
      'tone_of_voice': toneOfVoice,
      'visual_style': visualStyle,
      'include_references': includeReferences,
      'include_interactive_elements': includeInteractiveElements,
      if (detailedOutline != null && detailedOutline!.isNotEmpty)
        'detailed_outline': detailedOutline,
    };
  }
}

/// 새 프로젝트 생성 위자드
class CreateProjectWizard extends StatefulWidget {
  const CreateProjectWizard({super.key});

  @override
  State<CreateProjectWizard> createState() => _CreateProjectWizardState();
}

class _CreateProjectWizardState extends State<CreateProjectWizard> {
  final _pageController = PageController();
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>()];

  // Step 1
  final _titleController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  String _selectedDuration = '10~15분';
  String _selectedTone = '전문적이고 신뢰감 있는';
  String _selectedStyle = '모던 & 미니멀';

  // Step 2
  final _overviewController = TextEditingController();
  final _outlineController = TextEditingController();
  bool _includeReferences = true;
  bool _includeInteractiveElements = false;

  int _currentStep = 0;

  final List<String> _durationOptions = [
    '5~10분',
    '10~15분',
    '15~20분',
    '20분 이상',
  ];

  final List<String> _toneOptions = [
    '전문적이고 신뢰감 있는',
    '친근하고 대화형',
    '활기차고 영감을 주는',
    '차분하고 학술적인',
  ];

  final List<String> _styleOptions = [
    '모던 & 미니멀',
    '비주얼 중심',
    '데이터 기반',
    '스토리텔링',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _targetAudienceController.dispose();
    _overviewController.dispose();
    _outlineController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleNext() async {
    final currentForm = _formKeys[_currentStep].currentState;
    if (currentForm?.validate() ?? false) {
      if (_currentStep == _formKeys.length - 1) {
        _submit();
      } else {
        _goToStep(_currentStep + 1);
      }
    }
  }

  void _submit() {
    final currentForm = _formKeys[_currentStep].currentState;
    if (!(currentForm?.validate() ?? false)) return;

    final audience = _targetAudienceController.text.trim().isEmpty
        ? '일반 학습자'
        : _targetAudienceController.text.trim();

    Navigator.of(context).pop(
      CreateProjectRequest(
        title: _titleController.text.trim(),
        overview: _overviewController.text.trim(),
        detailedOutline: _outlineController.text.trim().isEmpty
            ? null
            : _outlineController.text.trim(),
        targetAudience: audience,
        estimatedDuration: _selectedDuration,
        toneOfVoice: _selectedTone,
        visualStyle: _selectedStyle,
        includeReferences: _includeReferences,
        includeInteractiveElements: _includeInteractiveElements,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Column(
          children: [
            _WizardHeader(
              currentStep: _currentStep,
              onStepTapped: (step) {
                if (step <= _currentStep) {
                  _goToStep(step);
                } else {
                  _handleNext();
                }
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepOne(context),
                  _buildStepTwo(context),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => _goToStep(_currentStep - 1),
                      child: const Text('이전'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(_currentStep == 1 ? '프로젝트 생성' : '다음'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '강의 기본 정보',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'AI가 강의를 이해할 수 있도록 핵심 정보를 입력해주세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '강의 제목',
                hintText: '예: 비즈니스 리더를 위한 생성형 AI 활용 전략',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '강의 제목을 입력해주세요';
                }
                if (value.trim().length < 4) {
                  return '4자 이상 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _targetAudienceController,
              decoration: const InputDecoration(
                labelText: '대상 청중',
                hintText: '예: 신입 마케터, 중급 개발자, 대학생 등',
              ),
            ),
            const SizedBox(height: 20),
            _ChoiceChips<String>(
              label: '예상 러닝 타임',
              options: _durationOptions,
              selectedValue: _selectedDuration,
              onChanged: (value) {
                setState(() => _selectedDuration = value);
              },
            ),
            const SizedBox(height: 20),
            _ChoiceChips<String>(
              label: '톤 & 분위기',
              options: _toneOptions,
              selectedValue: _selectedTone,
              onChanged: (value) {
                setState(() => _selectedTone = value);
              },
            ),
            const SizedBox(height: 20),
            _ChoiceChips<String>(
              label: '슬라이드 스타일',
              options: _styleOptions,
              selectedValue: _selectedStyle,
              onChanged: (value) {
                setState(() => _selectedStyle = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 브리프',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '생성할 강의의 개요와 세부 내용을 입력해주세요. 자세할수록 더 정밀한 슬라이드를 생성합니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _overviewController,
              decoration: const InputDecoration(
                labelText: '강의 개요',
                hintText: '강의 목표, 주요 메시지 등을 요약해주세요.',
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '강의 개요를 입력해주세요';
                }
                if (value.trim().length < 20) {
                  return '좀 더 구체적으로 작성해주세요 (20자 이상)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _outlineController,
              decoration: const InputDecoration(
                labelText: '상세 개요 (선택)',
                hintText: '슬라이드별 필수 포인트, 사례, 데이터 등을 입력해주세요.',
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('참고 자료 / 출처 포함'),
              subtitle: const Text('AI가 신뢰 가능한 근거를 찾아 슬라이드마다 출처를 제공합니다.'),
              value: _includeReferences,
              onChanged: (value) {
                setState(() => _includeReferences = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('퀴즈 · 체크리스트 등 인터랙티브 요소 포함'),
              subtitle: const Text('학습 유지력을 높이기 위한 체크포인트, 퀴즈 슬라이드를 추가합니다.'),
              value: _includeInteractiveElements,
              onChanged: (value) {
                setState(() => _includeInteractiveElements = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.currentStep,
    required this.onStepTapped,
  });

  final int currentStep;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('기본 정보', Icons.view_quilt_outlined),
      ('AI 브리프', Icons.auto_stories_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          const FlutterLogo(size: 28),
          const SizedBox(width: 12),
          const Text(
            '새 강의 프로젝트',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          for (int i = 0; i < steps.length; i++) ...[
            GestureDetector(
              onTap: () => onStepTapped(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: currentStep == i
                      ? AppTheme.primaryColor.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      steps[i].$2,
                      size: 18,
                      color: currentStep >= i
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      steps[i].$1,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: currentStep >= i
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              Icon(
                Icons.navigate_next,
                color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceChips<T> extends StatelessWidget {
  const _ChoiceChips({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return ChoiceChip(
              label: Text(option.toString()),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
