import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import 'local_project_repository.dart';

Map<String, dynamic> _sanitizeForFirestore(Map<String, dynamic> input) {
  final sanitized = <String, dynamic>{};
  input.forEach((key, value) {
    sanitized[key] = _sanitizeValue(value);
  });
  return sanitized;
}

List<dynamic> _sanitizeList(List<dynamic> list) {
  return list
      .map((value) => _sanitizeValue(value))
      .where((value) => value != null)
      .toList();
}

dynamic _sanitizeValue(dynamic value) {
  if (value == null) return null;
  if (value is num || value is bool || value is String) return value;
  if (value is DateTime) return Timestamp.fromDate(value);
  if (value is Timestamp || value is GeoPoint) return value;
  if (value is List) {
    return _sanitizeList(value);
  }
  if (value is Map) {
    return _sanitizeForFirestore(
      value.map((key, val) => MapEntry(key.toString(), _sanitizeValue(val))),
    );
  }
  if (value is Enum) return value.name;
  return value.toString();
}

Future<T> _executeWithRetry<T>({
  required Future<T> Function() task,
  required String action,
  required String projectId,
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 400),
}) async {
  final rng = Random();
  int attempt = 0;
  while (true) {
    attempt += 1;
    try {
      debugPrint('[Firestore] $action (project: $projectId, attempt: $attempt)');
      final result = await task();
      debugPrint('[Firestore] $action 성공 (project: $projectId)');
      return result;
    } catch (error, stackTrace) {
      debugPrint('[Firestore] $action 실패 (project: $projectId, attempt: $attempt) -> $error');
      if (attempt >= maxAttempts) {
        debugPrint('[Firestore] $action 포기 (project: $projectId)');
        Error.throwWithStackTrace(error, stackTrace);
      }
      final jitter = Duration(milliseconds: rng.nextInt(250));
      final delay = baseDelay * attempt + jitter;
      await Future.delayed(delay);
    }
  }
}

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
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return LectureProject.fromJson({
        'id': snapshot.id,
        ...data,
      });
    });
  }

  @override
  Future<void> createProject(String userId, LectureProject project) async {
    await _executeWithRetry(
      task: () async {
        final projectData = _sanitizeForFirestore(project.toJson())
          ..remove('id');
        
        await _firestore
            .collection(_projectsPath(userId))
            .doc(project.id)
            .set(projectData);
      },
      action: '프로젝트 생성',
      projectId: project.id,
    );
  }

  @override
  Future<void> updateProject(String userId, LectureProject project) async {
    await _executeWithRetry(
      task: () async {
        final projectData = _sanitizeForFirestore(project.toJson())
          ..remove('id')
          ..['updatedAt'] = Timestamp.now();
        
        await _firestore
            .collection(_projectsPath(userId))
            .doc(project.id)
            .update(projectData);
      },
      action: '프로젝트 업데이트',
      projectId: project.id,
    );
  }

  @override
  Future<void> deleteProject(String userId, String projectId) async {
    await _executeWithRetry(
      task: () async {
        await _firestore
            .collection(_projectsPath(userId))
            .doc(projectId)
            .delete();
      },
      action: '프로젝트 삭제',
      projectId: projectId,
    );
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
    await _executeWithRetry(
      task: () async {
        final projectDoc = await _firestore
            .collection(_projectsPath(userId))
            .doc(projectId)
            .get();

        if (!projectDoc.exists) {
          throw Exception('프로젝트를 찾을 수 없습니다');
        }

        final projectData = _sanitizeForFirestore(projectDoc.data()!)
          ..['sharedBy'] = userId
          ..['sharedAt'] = Timestamp.now();

        await _firestore
            .collection('shared_projects')
            .doc(projectId)
            .set(projectData);
      },
      action: '프로젝트 공유',
      projectId: projectId,
    );
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

