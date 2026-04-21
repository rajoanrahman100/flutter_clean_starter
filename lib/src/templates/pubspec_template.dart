class PubspecTemplate {
  static String generate({
    required String projectName,
    required String stateManagement,
  }) {
    final stateManagementDeps = stateManagement == 'Riverpod'
        ? '''
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5'''
        : '''
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5''';

    final riverpodDevDeps = stateManagement == 'Riverpod'
        ? '''
  riverpod_generator: ^2.4.0'''
        : '';

    return '''
name: $projectName
description: A Flutter application.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
$stateManagementDeps

  # Navigation
  go_router: ^13.2.0

  # Networking
  dio: ^5.4.3
  pretty_dio_logger: ^1.3.1

  # Dependency injection
  get_it: ^7.6.7
  injectable: ^2.4.1

  # Storage
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.0.0

  # Utils
  intl: ^0.19.0
  logger: ^2.3.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  dartz: ^0.10.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  injectable_generator: ^2.4.2
  mocktail: ^1.0.3
$riverpodDevDeps

flutter:
  uses-material-design: true
''';
  }
}