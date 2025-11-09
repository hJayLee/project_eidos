import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/auth_service.dart';

part 'auth_provider.g.dart';

/// 인증 서비스 Provider
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

/// 현재 사용자 상태 Provider
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
}

/// 현재 사용자 Provider
@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull;
}

/// 현재 사용자 ID Provider
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
}

/// 로그인 상태 Provider
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
}

/// 익명 사용자 여부 Provider
@riverpod
bool isAnonymousUser(IsAnonymousUserRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? false;
}

