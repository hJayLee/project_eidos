import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

/// 프로젝트 저장소 인터페이스
abstract class ProjectRepository {
  Stream<List<LectureProject>> watchProjects(String userId);
  Stream<LectureProject?> watchProject(String userId, String projectId);
  Future<void> createProject(String userId, LectureProject project);
  Future<void> updateProject(String userId, LectureProject project);
  Future<void> deleteProject(String userId, String projectId);
  Future<List<LectureProject>> searchProjects(String userId, String query);
  Future<void> shareProject(String userId, String projectId);
  Future<LectureProject?> getSharedProject(String projectId);
}

/// 로컬 저장소 프로젝트 저장소
class LocalProjectRepository implements ProjectRepository {
  static const String _projectsKey = 'projects';
  
  @override
  Stream<List<LectureProject>> watchProjects(String userId) async* {
    final projects = await _getProjects(userId);
    yield projects;
  }
  
  @override
  Stream<LectureProject?> watchProject(String userId, String projectId) async* {
    final projects = await _getProjects(userId);
    final project = projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw Exception('프로젝트를 찾을 수 없습니다'),
    );
    yield project;
  }
  
  @override
  Future<void> createProject(String userId, LectureProject project) async {
    final projects = await _getProjects(userId);
    projects.add(project);
    await _saveProjects(userId, projects);
  }
  
  @override
  Future<void> updateProject(String userId, LectureProject project) async {
    final projects = await _getProjects(userId);
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      await _saveProjects(userId, projects);
    }
  }
  
  @override
  Future<void> deleteProject(String userId, String projectId) async {
    final projects = await _getProjects(userId);
    projects.removeWhere((p) => p.id == projectId);
    await _saveProjects(userId, projects);
  }
  
  @override
  Future<List<LectureProject>> searchProjects(String userId, String query) async {
    final projects = await _getProjects(userId);
    if (query.isEmpty) return projects;
    
    return projects.where((project) {
      return project.title.toLowerCase().contains(query.toLowerCase()) ||
             project.description.toLowerCase().contains(query.toLowerCase()) ||
             project.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }
  
  @override
  Future<void> shareProject(String userId, String projectId) async {
    // 로컬에서는 공유 기능 미지원
    throw UnsupportedError('로컬 저장소에서는 공유 기능을 지원하지 않습니다');
  }
  
  @override
  Future<LectureProject?> getSharedProject(String projectId) async {
    // 로컬에서는 공유 기능 미지원
    return null;
  }
  
  Future<List<LectureProject>> _getProjects(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_projectsKey}_$userId';
    final projectsJson = prefs.getStringList(key) ?? [];
    
    return projectsJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return LectureProject.fromJson(data);
    }).toList();
  }
  
  Future<void> _saveProjects(String userId, List<LectureProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_projectsKey}_$userId';
    final projectsJson = projects.map((project) {
      return jsonEncode(project.toJson());
    }).toList();
    
    await prefs.setStringList(key, projectsJson);
  }
}
