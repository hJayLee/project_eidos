import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/avatar_job.dart';

/// 강사 프로필 설정 페이지
class InstructorProfilePage extends StatefulWidget {
  const InstructorProfilePage({super.key});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  static const _backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:5001',
  );

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

  // 비디오
  String? _videoUrl;
  String? _videoError;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _videoController?.dispose();
    _jobSubscription?.cancel();
    super.dispose();
  }

  // Firestore 작업 리스닝 시작
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

        // 완료 시 비디오 로드
        if (job.status == AvatarJobStatus.completed && job.videoUrl != null) {
          if (_videoUrl != job.videoUrl) {
            _loadVideo(job.videoUrl!);
          }
          _showSnackBar('아바타 영상이 생성되었습니다!', isSuccess: true);
        }

        // 실패 시
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

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      _showSnackBar('이미지 데이터를 불러오지 못했습니다.');
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

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      _showSnackBar('오디오 데이터를 불러오지 못했습니다.');
      return;
    }

    setState(() {
      _audioBytes = file.bytes;
      _audioName = file.name;
    });
  }

  Future<void> _recordAudio() async {
    // TODO: 음성 녹음 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('음성 녹음 기능은 준비중입니다')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
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
      // Cloud Tasks 엔드포인트 호출 (수시간 처리 가능)
      final uri = Uri.parse('$_backendBaseUrl/generate-with-tasks');
      final request = http.MultipartRequest('POST', uri)
        ..fields['userId'] = 'user_123' // TODO: 실제 사용자 ID
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
          
          // Firestore 리스닝 시작
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
          _statusMessage =
              '생성 요청 실패 (${response.statusCode})\n${response.body}';
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

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('강사 프로필 설정'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 섹션 1: 강사 정보
              _buildSection1(),

              const SizedBox(height: 32),

              // 섹션 2: AI 아바타 등록
              _buildSection2(),
            ],
          ),
        ),
      ),
    );
  }

  /// 섹션 1: 강사명, 강사소개 입력
  Widget _buildSection1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '강사 정보',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '강사 프로필에 표시될 정보를 입력하세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 24),

        // 강사명 입력
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '강사명',
            hintText: '예: 홍길동',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '강사명을 입력해주세요';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // 강사소개 입력
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: '강사소개',
            hintText: '강사에 대한 간단한 소개를 입력하세요',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          minLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '강사소개를 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 섹션 2: AI 아바타 등록
  Widget _buildSection2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI 아바타 등록',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '아바타 영상 생성을 위한 이미지와 음성을 업로드하세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 24),

        // 이미지 업로드
        _UploadTile(
          title: '정면 이미지',
          subtitle: _imageName ?? 'PNG, JPG 지원',
          icon: Icons.image_outlined,
          onTap: _isSubmitting ? null : _pickImage,
        ),

        const SizedBox(height: 16),

        // 음성 파일 업로드
        _UploadTile(
          title: '오디오',
          subtitle: _audioName ?? 'WAV, MP3, M4A, AAC 지원',
          icon: Icons.audiotrack,
          onTap: _isSubmitting ? null : _pickAudio,
        ),

        const SizedBox(height: 24),

        // 아바타 영상 생성 버튼
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _isSubmitting ? '생성 중...' : '아바타 영상 생성',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 상태 메시지 및 진행률
        if (_currentJob != null)
          _buildJobProgressCard(_currentJob!),

        if (_statusMessage != null && _currentJob == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _statusMessage!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // 비디오 로딩
        if (_isVideoLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),

        // 비디오 오류
        if (_videoError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2B1D1F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _videoError!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(0xFFFFB3B3),
              ),
            ),
          ),

        // 비디오 미리보기
        if (_videoController != null && _videoController!.value.isInitialized)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _VideoPreview(
              controller: _videoController!,
              videoUrl: _videoUrl ?? '',
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 작업 진행 상황 카드
  Widget _buildJobProgressCard(AvatarJob job) {
    final progress = job.progress;
    final isProcessing = job.status == AvatarJobStatus.processing;
    final isCompleted = job.status == AvatarJobStatus.completed;
    final isFailed = job.status == AvatarJobStatus.failed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getJobStatusColor(job.status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 헤더
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getJobStatusColor(job.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getJobStatusText(job.status),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isProcessing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 진행률 바
          if (isProcessing || isCompleted) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getJobStatusColor(job.status),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // 진행 단계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.stepNumber} / ${progress.totalSteps} 단계',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${progress.percentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getJobStatusColor(job.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // 현재 단계 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getStepIcon(progress.currentStep),
                  size: 20,
                  color: _getJobStatusColor(job.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    progress.displayText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 오류 메시지
          if (isFailed && job.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      job.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // 완료 시간
          if (isCompleted && job.completedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              '완료 시간: ${_formatDateTime(job.completedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getJobStatusColor(AvatarJobStatus status) {
    switch (status) {
      case AvatarJobStatus.pending:
        return Colors.grey;
      case AvatarJobStatus.processing:
        return Colors.blue;
      case AvatarJobStatus.completed:
        return Colors.green;
      case AvatarJobStatus.failed:
        return Colors.red;
    }
  }

  String _getJobStatusText(AvatarJobStatus status) {
    switch (status) {
      case AvatarJobStatus.pending:
        return '대기 중';
      case AvatarJobStatus.processing:
        return '생성 중';
      case AvatarJobStatus.completed:
        return '생성 완료';
      case AvatarJobStatus.failed:
        return '생성 실패';
    }
  }

  IconData _getStepIcon(String step) {
    switch (step) {
      case 'avatar_creation':
        return Icons.person_add_outlined;
      case 'voice_cloning':
        return Icons.record_voice_over;
      case 'video_generation':
        return Icons.video_library;
      case 'completed':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF151A28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              onTap == null ? Icons.hourglass_empty : Icons.upload_file,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.controller,
    required this.videoUrl,
  });

  final VideoPlayerController controller;
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151A28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '생성된 미리보기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(controller),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: IconButton(
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            videoUrl,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          )
        ],
      ),
    );
  }
}
