// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectRepositoryHash() => r'd3fa47c6ace86afba6989c621fa205ad79b035bd';

/// 프로젝트 저장소 Provider
/// 인증된 사용자가 있으면 Firestore 사용, 없으면 로컬 저장소 사용
///
/// Copied from [projectRepository].
@ProviderFor(projectRepository)
final projectRepositoryProvider =
    AutoDisposeProvider<ProjectRepository>.internal(
      projectRepository,
      name: r'projectRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProjectRepositoryRef = AutoDisposeProviderRef<ProjectRepository>;
String _$effectiveUserIdHash() => r'80bfa085e219a614a880f70ef93ddd5b177b3483';

/// 실제 사용자 ID 또는 임시 ID 반환
///
/// Copied from [effectiveUserId].
@ProviderFor(effectiveUserId)
final effectiveUserIdProvider = AutoDisposeProvider<String>.internal(
  effectiveUserId,
  name: r'effectiveUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$effectiveUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EffectiveUserIdRef = AutoDisposeProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
