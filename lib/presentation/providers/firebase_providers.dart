import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firestore_project_repository.dart';
import '../../data/repositories/local_project_repository.dart';
import 'auth_provider.dart';

part 'firebase_providers.g.dart';

/// 프로젝트 저장소 Provider
/// 인증된 사용자가 있으면 Firestore 사용, 없으면 로컬 저장소 사용
@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final userId = ref.watch(currentUserIdProvider);
  
  // 인증된 사용자가 있으면 Firestore 사용
  if (userId != null) {
    print('📦 Firestore 저장소 사용 (사용자 ID: $userId)');
    return FirestoreProjectRepository();
  }
  
  // 인증되지 않은 경우 로컬 저장소 사용 (임시)
  print('📦 로컬 저장소 사용 (임시 사용자 ID: temp_user)');
  return LocalProjectRepository();
}

/// 실제 사용자 ID 또는 임시 ID 반환
@riverpod
String effectiveUserId(EffectiveUserIdRef ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId ?? 'temp_user';
}

/// 현재 사용자 ID Provider (인증 Provider에서 가져옴)
/// 이 Provider는 auth_provider.dart의 currentUserIdProvider를 재export합니다.
