import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase 설정 확인 유틸리티
class FirebaseConfigChecker {
  /// Google 인증 설정 확인
  static Future<Map<String, dynamic>> checkGoogleAuthConfig() async {
    final results = <String, dynamic>{};
    
    try {
      // Firebase 초기화 확인
      final auth = FirebaseAuth.instance;
      results['firebase_initialized'] = true;
      
      // 현재 사용자 확인
      results['current_user'] = auth.currentUser?.uid;
      results['is_authenticated'] = auth.currentUser != null;
      
      if (kIsWeb) {
        // 웹 플랫폼 확인
        results['platform'] = 'web';
        results['auth_domain'] = auth.app.options.authDomain;
        results['project_id'] = auth.app.options.projectId;
      } else {
        results['platform'] = 'not_web';
      }
      
      results['status'] = 'success';
    } catch (e) {
      results['status'] = 'error';
      results['error'] = e.toString();
    }
    
    return results;
  }
  
  /// 설정 정보 출력
  static void printConfigInfo() {
    print('\n📋 Firebase 설정 정보:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      final auth = FirebaseAuth.instance;
      print('✅ Firebase 초기화: 성공');
      print('📦 프로젝트 ID: ${auth.app.options.projectId}');
      print('🌐 Auth Domain: ${auth.app.options.authDomain}');
      print('🔑 API Key: ${auth.app.options.apiKey.substring(0, 20)}...');
      
      if (auth.currentUser != null) {
        print('👤 현재 사용자: ${auth.currentUser?.uid}');
        print('📧 이메일: ${auth.currentUser?.email}');
      } else {
        print('👤 현재 사용자: 없음');
      }
    } catch (e) {
      print('❌ 설정 확인 실패: $e');
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}

