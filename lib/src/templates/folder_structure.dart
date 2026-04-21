class FolderStructure {
  static List<String> folders(List<String> features) {
    final base = [
      'lib/core/error',
      'lib/core/network',
      'lib/core/usecase',
      'lib/core/utils',
      'lib/core/constants',
      'lib/core/theme',
      'lib/core/router',
      'lib/core/config',
      'lib/di',
      'test/core',
    ];

    final featureFolders = features.expand((feature) => [
      'lib/features/$feature/data/datasources',
      'lib/features/$feature/data/models',
      'lib/features/$feature/data/repositories',
      'lib/features/$feature/domain/entities',
      'lib/features/$feature/domain/repositories',
      'lib/features/$feature/domain/usecases',
      'lib/features/$feature/presentation/bloc',
      'lib/features/$feature/presentation/pages',
      'lib/features/$feature/presentation/widgets',
      'test/features/$feature',
    ]).toList();

    return [...base, ...featureFolders];
  }
}