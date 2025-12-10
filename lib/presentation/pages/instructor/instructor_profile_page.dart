import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/backend_config.dart';
import '../../../data/models/avatar_job.dart';

/// 강사 프로필 설정 페이지
class InstructorProfilePage extends StatefulWidget {
  const InstructorProfilePage({super.key});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  // Backend URL을 중앙에서 관리
  String get _backendBaseUrl => BackendConfig.visionStoryUrl;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  // 파일 데이터
  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _audioBytes;
  String? _audioName;

  // 생성 상태
  bool _isSubmitting = false;
  String? _statusMessage;

  // Firestore 리스닝
  StreamSubscription? _jobSubscription;
  AvatarJob? _currentJob;
  
  // 사용자 정보
  User? _currentUser;
  bool _isLoadingJobs = true;

  // 비디오
  String? _videoUrl;
  String? _videoError;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadJobs();
  }

  // 로그인 확인 및 작업 로드
  Future<void> _checkAuthAndLoadJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (!mounted) return;
    
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLoginRequiredDialog();
        }
      });
      return;
    }

    setState(() {
      _currentUser = user;
    });

    await _loadLatestJob();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('로그인 필요'),
        content: const Text('강사 프로필 설정을 위해 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  // 가장 최근 작업 로드 (진행 중인 작업 확인용)
  Future<void> _loadLatestJob() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingJobs = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('avatarJobs')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(1) // 가장 최근 1개만 확인
          .get();

      if (!mounted) return;

      setState(() {
        _isLoadingJobs = false;
      });

      if (querySnapshot.docs.isEmpty) return;

      final job = AvatarJob.fromFirestore(querySnapshot.docs.first);

      // 진행 중이거나 대기 중인 경우 상태 복원 및 리스닝 시작
      if (job.status == AvatarJobStatus.processing ||
          job.status == AvatarJobStatus.pending) {
        _listenToJob(job.jobId);
        _restoreJobState(job);
      } else if (job.status == AvatarJobStatus.completed) {
        // 완료된 작업도 보여주기 (선택 사항, 여기서는 마지막 작업 결과 확인용으로 유지)
        setState(() {
          _currentJob = job;
          _statusMessage = '마지막 작업: ${job.progress.displayText}';
        });
        
        if (job.videoUrl != null) {
          _loadVideo(job.videoUrl!);
        }
        // 완료된 작업이면 폼 내용은 채워주지만 수정 가능하게
        _nameController.text = job.instructorName;
        _bioController.text = job.instructorBio;
      }
    } catch (e) {
      debugPrint('작업 로드 실패: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoadingJobs = false;
      });
    }
  }

  void _restoreJobState(AvatarJob job) {
    setState(() {
      _nameController.text = job.instructorName;
      _bioController.text = job.instructorBio;
      
      _isSubmitting = true;
      _statusMessage = job.progress.displayText;
      
      _imageName = "이전 업로드 이미지";
      _audioName = "이전 업로드 오디오";
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _videoController?.dispose();
    _jobSubscription?.cancel();
    super.dispose();
  }

  void _listenToJob(String jobId) {
    _jobSubscription?.cancel();
    
    _jobSubscription = FirebaseFirestore.instance
        .collection('avatarJobs')
        .doc(jobId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists || !mounted) return;

        final job = AvatarJob.fromFirestore(snapshot);
        
        setState(() {
          _currentJob = job;
          _statusMessage = job.progress.displayText;
        });

        if (job.status == AvatarJobStatus.completed && job.videoUrl != null) {
          if (_videoUrl != job.videoUrl) {
            _loadVideo(job.videoUrl!);
          }
          _showSnackBar('아바타 영상이 생성되었습니다!', isSuccess: true);
        }

        if (job.status == AvatarJobStatus.failed) {
          setState(() {
            _videoError = job.errorMessage ?? '알 수 없는 오류';
            _isSubmitting = false;
          });
          _showSnackBar('영상 생성 실패: ${job.errorMessage}', isSuccess: false);
        }
      },
      onError: (error) {
        debugPrint('Firestore 리스닝 오류: $error');
        _showSnackBar('작업 상태 확인 중 오류 발생', isSuccess: false);
      },
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showSnackBar('이미지 데이터를 불러오지 못했습니다.', isSuccess: false);
      return;
    }

    setState(() {
      _imageBytes = file.bytes;
      _imageName = file.name;
    });
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'm4a', 'aac'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showSnackBar('오디오 데이터를 불러오지 못했습니다.', isSuccess: false);
      return;
    }

    setState(() {
      _audioBytes = file.bytes;
      _audioName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentUser == null) {
      _showSnackBar('로그인이 필요합니다', isSuccess: false);
      _showLoginRequiredDialog();
      return;
    }

    if (_imageBytes == null || _audioBytes == null) {
      _showSnackBar('이미지와 오디오 파일을 모두 첨부해주세요.', isSuccess: false);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = '생성 요청을 전송 중입니다...';
      _currentJob = null;
      _videoUrl = null;
      _videoError = null;
      _videoController?.dispose();
      _videoController = null;
    });

    try {
      final uri = Uri.parse('$_backendBaseUrl/generate-with-tasks');
      final request = http.MultipartRequest('POST', uri)
        ..fields['userId'] = _currentUser!.uid
        ..fields['instructorName'] = _nameController.text
        ..fields['instructorBio'] = _bioController.text
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: _imageName ?? 'image.png',
          ),
        )
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            _audioBytes!,
            filename: _audioName ?? 'audio.wav',
          ),
        );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String? jobId = body['jobId'] as String?;

        if (!mounted) return;

        if (jobId != null && jobId.isNotEmpty) {
          setState(() {
            _statusMessage = '작업이 시작되었습니다. 잠시만 기다려주세요...';
          });
          _listenToJob(jobId);
          _showSnackBar('영상 생성이 시작되었습니다 (ID: $jobId)', isSuccess: true);
        } else {
          setState(() {
            _statusMessage = '작업 ID를 받지 못했습니다.';
            _isSubmitting = false;
          });
        }
      } else {
        setState(() {
          _statusMessage = '생성 요청 실패 (${response.statusCode})\n${response.body}';
          _isSubmitting = false;
        });
      }
    } catch (error) {
      setState(() {
        _statusMessage = '요청 중 오류가 발생했습니다: $error';
        _isSubmitting = false;
      });
      _showSnackBar('오류: $error', isSuccess: false);
    }
  }

  Future<void> _loadVideo(String url) async {
    setState(() {
      _isVideoLoading = true;
      _videoError = null;
    });

    final previousController = _videoController;
    _videoController = null;
    await previousController?.pause();
    await previousController?.dispose();

    VideoPlayerController? tempController;

    try {
      tempController = VideoPlayerController.networkUrl(Uri.parse(url));
      await tempController.initialize();
      await tempController.setLooping(true);
      await tempController.play();

      if (!mounted) {
        await tempController.dispose();
        return;
      }

      setState(() {
        _videoController = tempController;
        _videoUrl = url;
      });
      tempController = null;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _videoController = null;
        _videoUrl = url;
        _videoError = '영상 로딩 실패: $error';
      });
    } finally {
      await tempController?.dispose();
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _jobSubscription?.cancel();
    setState(() {
      _isSubmitting = false;
      _statusMessage = null;
      _currentJob = null;
      _videoUrl = null;
      _videoError = null;
      _videoController?.dispose();
      _videoController = null;
      
      _nameController.clear();
      _bioController.clear();
      _imageBytes = null;
      _imageName = null;
      _audioBytes = null;
      _audioName = null;
    });
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppConstants.successColor : AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingJobs && _currentUser != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('강사 프로필 설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('강사 프로필 설정'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Theme.of(context).dividerTheme.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 작업 이력 섹션 제거됨
              
              _buildSectionHeader('강사 정보', '강사 프로필에 표시될 정보를 입력하세요'),
              const SizedBox(height: 24),
              _buildSection1(),
              
              const SizedBox(height: 48),
              
              _buildSectionHeader('AI 아바타 등록', '아바타 영상 생성을 위한 이미지와 음성을 업로드하세요'),
              const SizedBox(height: 24),
              _buildSection2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  // _buildJobHistorySection 제거됨
  // _buildJobHistoryCard 제거됨
  // _buildStatusIcon 제거됨

  Color _getJobStatusColor(AvatarJobStatus status) {
    switch (status) {
      case AvatarJobStatus.pending: return AppConstants.textSecondaryColor;
      case AvatarJobStatus.processing: return AppConstants.infoColor;
      case AvatarJobStatus.completed: return AppConstants.successColor;
      case AvatarJobStatus.failed: return AppConstants.errorColor;
    }
  }

  String _getJobStatusText(AvatarJobStatus status) {
    switch (status) {
      case AvatarJobStatus.pending: return '대기 중';
      case AvatarJobStatus.processing: return '생성 중';
      case AvatarJobStatus.completed: return '완료';
      case AvatarJobStatus.failed: return '실패';
    }
  }

  // _formatDateTime 제거됨 (더 이상 사용 안함)

  Widget _buildSection1() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          enabled: !_isSubmitting,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            labelText: '강사명',
            hintText: '예: 홍길동',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? '강사명을 입력해주세요' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          enabled: !_isSubmitting,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            labelText: '강사소개',
            hintText: '강사에 대한 간단한 소개를 입력하세요',
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: (value) => value == null || value.trim().isEmpty ? '강사소개를 입력해주세요' : null,
        ),
      ],
    );
  }

  Widget _buildSection2() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _UploadTile(
                title: '정면 이미지',
                subtitle: _imageName ?? 'PNG, JPG',
                icon: Icons.image_outlined,
                onTap: _isSubmitting ? null : _pickImage,
                isFilled: _imageName != null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UploadTile(
                title: '오디오',
                subtitle: _audioName ?? 'MP3, WAV',
                icon: Icons.audiotrack_outlined,
                onTap: _isSubmitting ? null : _pickAudio,
                isFilled: _audioName != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _isSubmitting ? '아바타 생성 중...' : '아바타 영상 생성하기',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_currentJob != null) _buildJobProgressCard(_currentJob!),
        if (_isSubmitting && _currentJob != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: _resetForm,
            child: const Text('새 작업 시작하기'),
          ),
        ],
        if (_statusMessage != null && _currentJob == null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.textSecondaryColor),
            ),
          ),
        if (_isVideoLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_videoError != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.errorColor.withOpacity(0.3)),
            ),
            child: Text(_videoError!, style: const TextStyle(color: AppConstants.errorColor)),
          ),
        if (_videoController != null && _videoController!.value.isInitialized)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _VideoPreview(controller: _videoController!, videoUrl: _videoUrl ?? ''),
          ),
      ],
    );
  }

  Widget _buildJobProgressCard(AvatarJob job) {
    final progress = job.progress;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('생성 진행률', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${progress.percentage}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage / 100,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppConstants.textSecondaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.displayText,
                  style: const TextStyle(color: AppConstants.textSecondaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getJobStatusIcon(AvatarJobStatus status) {
    switch (status) {
      case AvatarJobStatus.pending: return Icons.schedule;
      case AvatarJobStatus.processing: return Icons.autorenew;
      case AvatarJobStatus.completed: return Icons.check_circle;
      case AvatarJobStatus.failed: return Icons.error;
    }
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isFilled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFilled ? colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isFilled ? colorScheme.primary : const Color(0xFF334155),
            width: isFilled ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFilled ? colorScheme.primary : const Color(0xFF334155),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFilled ? Icons.check : icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isFilled ? colorScheme.primary : AppConstants.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.controller, required this.videoUrl});

  final VideoPlayerController controller;
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 48,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    controller.value.isPlaying ? controller.pause() : controller.play();
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardTheme.color,
            child: Text(
              '생성된 비디오 URL: $videoUrl',
              style: const TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
