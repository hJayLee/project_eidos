// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectByIdHash() => r'f496cc45663058c7a27eb046cc275854c49cb675';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 프로젝트 ID로 단일 프로젝트 로드
///
/// Copied from [projectById].
@ProviderFor(projectById)
const projectByIdProvider = ProjectByIdFamily();

/// 프로젝트 ID로 단일 프로젝트 로드
///
/// Copied from [projectById].
class ProjectByIdFamily extends Family<AsyncValue<LectureProject?>> {
  /// 프로젝트 ID로 단일 프로젝트 로드
  ///
  /// Copied from [projectById].
  const ProjectByIdFamily();

  /// 프로젝트 ID로 단일 프로젝트 로드
  ///
  /// Copied from [projectById].
  ProjectByIdProvider call(String projectId) {
    return ProjectByIdProvider(projectId);
  }

  @override
  ProjectByIdProvider getProviderOverride(
    covariant ProjectByIdProvider provider,
  ) {
    return call(provider.projectId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'projectByIdProvider';
}

/// 프로젝트 ID로 단일 프로젝트 로드
///
/// Copied from [projectById].
class ProjectByIdProvider extends AutoDisposeStreamProvider<LectureProject?> {
  /// 프로젝트 ID로 단일 프로젝트 로드
  ///
  /// Copied from [projectById].
  ProjectByIdProvider(String projectId)
    : this._internal(
        (ref) => projectById(ref as ProjectByIdRef, projectId),
        from: projectByIdProvider,
        name: r'projectByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$projectByIdHash,
        dependencies: ProjectByIdFamily._dependencies,
        allTransitiveDependencies: ProjectByIdFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  ProjectByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  Override overrideWith(
    Stream<LectureProject?> Function(ProjectByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectByIdProvider._internal(
        (ref) => create(ref as ProjectByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<LectureProject?> createElement() {
    return _ProjectByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectByIdProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProjectByIdRef on AutoDisposeStreamProviderRef<LectureProject?> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _ProjectByIdProviderElement
    extends AutoDisposeStreamProviderElement<LectureProject?>
    with ProjectByIdRef {
  _ProjectByIdProviderElement(super.provider);

  @override
  String get projectId => (origin as ProjectByIdProvider).projectId;
}

String _$projectListHash() => r'7f12ac483b86645e3cba7fb45d839c4a8915ede1';

/// 프로젝트 목록 상태 관리 (Firebase 연동)
///
/// Copied from [ProjectList].
@ProviderFor(ProjectList)
final projectListProvider =
    AutoDisposeAsyncNotifierProvider<
      ProjectList,
      List<LectureProject>
    >.internal(
      ProjectList.new,
      name: r'projectListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProjectList = AutoDisposeAsyncNotifier<List<LectureProject>>;
String _$currentProjectHash() => r'ccaac21d1e1a5a07fc305818e4f72399d3fc6087';

/// 현재 선택된 프로젝트 상태 관리
///
/// Copied from [CurrentProject].
@ProviderFor(CurrentProject)
final currentProjectProvider =
    AutoDisposeNotifierProvider<CurrentProject, LectureProject?>.internal(
      CurrentProject.new,
      name: r'currentProjectProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentProjectHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentProject = AutoDisposeNotifier<LectureProject?>;
String _$projectCreationHash() => r'861e30c1360c810d62d4153b7d0458264599a8b0';

/// 프로젝트 생성 상태 관리
///
/// Copied from [ProjectCreation].
@ProviderFor(ProjectCreation)
final projectCreationProvider =
    AutoDisposeNotifierProvider<ProjectCreation, ProjectCreationState>.internal(
      ProjectCreation.new,
      name: r'projectCreationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectCreationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProjectCreation = AutoDisposeNotifier<ProjectCreationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
