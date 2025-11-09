import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'core/utils/firebase_config_checker.dart';
import 'presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공!');
    
    // 설정 정보 출력
    FirebaseConfigChecker.printConfigInfo();
    
    // 현재 사용자 확인
    final authService = AuthService();
    if (authService.currentUser != null) {
      print('✅ 이미 로그인됨: ${authService.currentUser?.uid}');
    } else {
      print('ℹ️ 로그인되지 않음 - 프로젝트 생성 시 로그인 요청됨');
    }
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
    // 오류가 발생해도 앱은 계속 실행 (로컬 모드로 동작)
  }
  
  runApp(
    const ProviderScope(
      child: EidosStudioApp(),
    ),
  );
}

class EidosStudioApp extends StatelessWidget {
  const EidosStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // 테마 설정 (Cursor AI 스타일)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // 기본 다크 모드
      
      // 홈 페이지
      home: const HomePage(),
      
      // 라우팅 설정 (현재는 Navigator.push 사용)
      routes: {
        '/home': (context) => const HomePage(),
      },
    );
  }
}