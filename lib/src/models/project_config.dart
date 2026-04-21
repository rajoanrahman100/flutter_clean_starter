class ProjectConfig {
  final String projectName;
  final String bundleId;
  final String stateManagement;
  final List<String> features;
  final bool useFlavors;
  final String organization;

  const ProjectConfig({
    required this.projectName,
    required this.bundleId,
    required this.stateManagement,
    required this.features,
    required this.useFlavors,
    required this.organization,
  });

  /// Derived from bundleId — everything before the last dot segment.
  String get orgFromBundleId {
    final parts = bundleId.split('.');
    return parts.length >= 2
        ? parts.sublist(0, parts.length - 1).join('.')
        : bundleId;
  }

  @override
  String toString() => '''
  Project   : $projectName
  Bundle ID : $bundleId
  State     : $stateManagement
  Features  : ${features.join(', ')}
  Flavors   : $useFlavors''';
}