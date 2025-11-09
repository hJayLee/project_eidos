import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import 'local_project_repository.dart';

/// Firestore 기반 프로젝트 저장소
class FirestoreProjectRepository implements ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 사용자별 프로젝트 컬렉션 경로
  String _projectsPath(String userId) => 'users/$userId/projects';

  @override
  Stream<List<LectureProject>> watchProjects(String userId) {
    return _firestore
        .collection(_projectsPath(userId))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LectureProject.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }

  @override
  Stream<LectureProject?> watchProject(String userId, String projectId) {
    return _firestore
        .collection(_projectsPath(userId))
        .doc(projectId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return LectureProject.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
    });
  }

  @override
  Future<void> createProject(String userId, LectureProject project) async {
    try {
      final projectData = project.toJson();
      // id는 문서 ID로 사용되므로 제거
      projectData.remove('id');
      
      await _firestore
          .collection(_projectsPath(userId))
          .doc(project.id)
          .set(projectData);
    } catch (e) {
      throw Exception('프로젝트 생성 실패: $e');
    }
  }

  @override
  Future<void> updateProject(String userId, LectureProject project) async {
    try {
      final projectData = project.toJson();
      // id는 문서 ID로 사용되므로 제거
      projectData.remove('id');
      // updatedAt 업데이트
      projectData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_projectsPath(userId))
          .doc(project.id)
          .update(projectData);
    } catch (e) {
      throw Exception('프로젝트 업데이트 실패: $e');
    }
  }

  @override
  Future<void> deleteProject(String userId, String projectId) async {
    try {
      await _firestore
          .collection(_projectsPath(userId))
          .doc(projectId)
          .delete();
    } catch (e) {
      throw Exception('프로젝트 삭제 실패: $e');
    }
  }

  @override
  Future<List<LectureProject>> searchProjects(
    String userId,
    String query,
  ) async {
    try {
      if (query.isEmpty) {
        final snapshot = await _firestore
            .collection(_projectsPath(userId))
            .orderBy('updatedAt', descending: true)
            .get();
        
        return snapshot.docs
            .map((doc) => LectureProject.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();
      }

      // Firestore는 대소문자 구분 검색만 지원하므로,
      // 클라이언트 측에서 필터링
      final snapshot = await _firestore
          .collection(_projectsPath(userId))
          .orderBy('updatedAt', descending: true)
          .get();

      final projects = snapshot.docs
          .map((doc) => LectureProject.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      final queryLower = query.toLowerCase();
      return projects.where((project) {
        return project.title.toLowerCase().contains(queryLower) ||
            project.description.toLowerCase().contains(queryLower) ||
            project.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      }).toList();
    } catch (e) {
      throw Exception('프로젝트 검색 실패: $e');
    }
  }

  @override
  Future<void> shareProject(String userId, String projectId) async {
    try {
      // 공유 프로젝트 컬렉션에 복사
      final projectDoc = await _firestore
          .collection(_projectsPath(userId))
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        throw Exception('프로젝트를 찾을 수 없습니다');
      }

      final projectData = projectDoc.data()!;
      projectData['sharedBy'] = userId;
      projectData['sharedAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection('shared_projects')
          .doc(projectId)
          .set(projectData);
    } catch (e) {
      throw Exception('프로젝트 공유 실패: $e');
    }
  }

  @override
  Future<LectureProject?> getSharedProject(String projectId) async {
    try {
      final doc = await _firestore
          .collection('shared_projects')
          .doc(projectId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return LectureProject.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('공유 프로젝트 로드 실패: $e');
    }
  }
}

