import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 사용자 인증 서비스
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 현재 사용자 ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// 이메일/비밀번호로 회원가입
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 표시 이름 설정
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 익명 로그인 (게스트 모드)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Google 로그인
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (!kIsWeb) {
        throw UnsupportedError('현재 웹 플랫폼만 지원됩니다');
      }

      print('\n🔐 Google 로그인 시작...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 현재 설정:');
      print('   - Auth Domain: ${_auth.app.options.authDomain}');
      print('   - Project ID: ${_auth.app.options.projectId}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters(<String, String>{
          'prompt': 'select_account',
        });

      print('🔐 Firebase Auth signInWithPopup 사용...');
      final userCredential = await _auth.signInWithPopup(googleProvider);

      print('✅ Firebase 로그인 성공: ${userCredential.user?.uid}');
      print('📧 사용자 이메일: ${userCredential.user?.email}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'popup-blocked') {
        print('⚠️ Google 로그인 팝업이 차단되었거나 취소되었습니다');
        throw Exception(
          'Google 로그인 팝업이 차단되었거나 취소되었습니다.\n'
          '브라우저 팝업 차단 설정을 확인하거나 다시 시도해주세요.',
        );
      }

      print('❌ Firebase Auth 오류: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      final errorMessage = e.toString();
      print('❌ Google 로그인 오류: $errorMessage');

      if (errorMessage.contains('취소') ||
          errorMessage.contains('popup_closed') ||
          errorMessage.contains('cancelled')) {
        throw Exception('Google 로그인이 취소되었습니다');
      }

      throw Exception('Google 로그인 실패: $e');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 이메일 인증 메일 전송
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// 사용자 프로필 업데이트
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
    }
  }

  /// 계정 삭제
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  /// 인증 예외 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다';
      case 'user-not-found':
        return '사용자를 찾을 수 없습니다';
      case 'wrong-password':
        return '비밀번호가 잘못되었습니다';
      case 'invalid-email':
        return '유효하지 않은 이메일입니다';
      case 'user-disabled':
        return '비활성화된 계정입니다';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요';
      case 'operation-not-allowed':
        return '허용되지 않은 작업입니다';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }
}

