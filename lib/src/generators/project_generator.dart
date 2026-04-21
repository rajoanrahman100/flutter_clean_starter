import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/project_config.dart';
import '../utils/console.dart';
import '../templates/pubspec_template.dart';
import '../templates/folder_structure.dart';
import '../templates/base_files.dart';

class ProjectGenerator {
  final ProjectConfig config;

  const ProjectGenerator({required this.config});

  Future<void> generate() async {
    final projectDir = Directory(
      p.join(Directory.current.path, config.projectName),
    );

    Console.blank();

    await _runFlutterCreate(projectDir);
    await _applyPubspec(projectDir);
    await _buildFolderStructure(projectDir);
    await _writeBaseFiles(projectDir);
    if (config.useFlavors) await _writeFlavors(projectDir);
    await _runPubGet(projectDir);

    _printDoneMessage();
  }

  Future<void> _runFlutterCreate(Directory projectDir) async {
    Console.step('Running flutter create...');

    final result = await Process.run('flutter', [
      'create',
      '--org', config.orgFromBundleId,
      '--project-name', config.projectName,
      projectDir.path,
    ]);

    if (result.exitCode != 0) {
      Console.error('flutter create failed:\n${result.stderr}');
      exit(1);
    }

    Console.success('Flutter project created.');
  }

  Future<void> _applyPubspec(Directory projectDir) async {
    Console.step('Writing pubspec.yaml...');

    final file = File(p.join(projectDir.path, 'pubspec.yaml'));
    await file.writeAsString(
      PubspecTemplate.generate(
        projectName: config.projectName,
        stateManagement: config.stateManagement,
      ),
    );

    Console.success('pubspec.yaml written.');
  }

  Future<void> _buildFolderStructure(Directory projectDir) async {
    Console.step('Building folder structure...');

    final folders = FolderStructure.folders(config.features);
    for (final folder in folders) {
      final dir = Directory(p.join(projectDir.path, folder));
      await dir.create(recursive: true);
      await File(p.join(dir.path, '.gitkeep')).create();
    }

    Console.success('Folder structure created.');
  }

  Future<void> _writeBaseFiles(Directory projectDir) async {
    Console.step('Writing base boilerplate files...');

    final files = BaseFiles.generate(config: config);

    for (final entry in files.entries) {
      final file = File(p.join(projectDir.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }

    Console.success('Base files written.');
  }

  Future<void> _writeFlavors(Directory projectDir) async {
    Console.step('Writing flavor configuration...');

    final flavorFiles = {
      'lib/core/config/app_config.dart': _appConfig(),
      'lib/core/config/flavor.dart': _flavorEnum(),
      'lib/main_dev.dart': _flavorMain('dev'),
      'lib/main_staging.dart': _flavorMain('staging'),
      'lib/main_prod.dart': _flavorMain('prod'),
      'FLAVORS.md': _flavorGuide(),
    };

    for (final entry in flavorFiles.entries) {
      final file = File(p.join(projectDir.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }

    await _configureAndroidFlavors(projectDir);

    Console.success('Flavor config written.');
  }

  Future<void> _configureAndroidFlavors(Directory projectDir) async {
    final ktsFile = File(p.join(projectDir.path, 'android/app/build.gradle.kts'));
    final groovyFile = File(p.join(projectDir.path, 'android/app/build.gradle'));

    if (await ktsFile.exists()) {
      final content = await ktsFile.readAsString();
      if (content.contains('flavorDimensions += "environment"')) return;

      final insertionPoint = '    buildTypes {';
      if (!content.contains(insertionPoint)) return;

      final updated = content.replaceFirst(
        insertionPoint,
        '''
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "${_titleCase(config.projectName)} Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".stg"
            resValue("string", "app_name", "${_titleCase(config.projectName)} Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "${_titleCase(config.projectName)}")
        }
    }

    buildTypes {
''',
      );

      await ktsFile.writeAsString(updated);
      return;
    }

    if (await groovyFile.exists()) {
      final content = await groovyFile.readAsString();
      if (content.contains('flavorDimensions "environment"')) return;

      final insertionPoint = '    buildTypes {';
      if (!content.contains(insertionPoint)) return;

      final updated = content.replaceFirst(
        insertionPoint,
        '''
    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            resValue "string", "app_name", "${_titleCase(config.projectName)} Dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".stg"
            resValue "string", "app_name", "${_titleCase(config.projectName)} Staging"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "${_titleCase(config.projectName)}"
        }
    }

    buildTypes {
''',
      );

      await groovyFile.writeAsString(updated);
    }
  }

  Future<void> _runPubGet(Directory projectDir) async {
    Console.step('Running flutter pub get...');

    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectDir.path,
    );

    if (result.exitCode != 0) {
      Console.error('flutter pub get failed:\n${result.stderr}');
      exit(1);
    }

    Console.success('Dependencies installed.');
  }

  void _printDoneMessage() {
    Console.blank();
    Console.success('Project "${config.projectName}" created successfully!');
    Console.blank();
    print('  Next steps:');
    print('    cd ${config.projectName}');
    print('    flutter pub run build_runner build --delete-conflicting-outputs');
    if (config.useFlavors) {
      print('    # Update lib/core/config/app_config.dart with your env values');
    }
    print('    code .');
    Console.blank();
  }

  String _appConfig() => '''
import 'flavor.dart';

class AppConfig {
  final Flavor flavor;
  final String baseUrl;
  final String appName;

  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
  });

  static late AppConfig current;

  static const dev = AppConfig(
    flavor: Flavor.dev,
    baseUrl: 'https://dev-api.yourserver.com',
    appName: '${config.projectName} DEV',
  );

  static const staging = AppConfig(
    flavor: Flavor.staging,
    baseUrl: 'https://staging-api.yourserver.com',
    appName: '${config.projectName} Staging',
  );

  static const prod = AppConfig(
    flavor: Flavor.prod,
    baseUrl: 'https://api.yourserver.com',
    appName: '${config.projectName}',
  );

  static void setFlavor(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        current = dev;
        break;
      case Flavor.staging:
        current = staging;
        break;
      case Flavor.prod:
        current = prod;
        break;
    }
  }
}
''';

  String _flavorEnum() => '''
enum Flavor { dev, staging, prod }
''';

  String _flavorMain(String flavor) {
    final flavorEnum = flavor == 'prod' ? 'Flavor.prod' : 'Flavor.$flavor';
    return '''
import 'package:flutter/material.dart';
import 'di/injection.dart';
import 'core/config/app_config.dart';
import 'core/config/flavor.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setFlavor($flavorEnum);
  await configureDependencies();
  runApp(const App());
}
''';
  }

  String _flavorGuide() => '''
# Flavor Setup

This project was generated with flavor support.

## Run Commands

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

## Android

Android product flavors are already configured in `android/app/build.gradle.kts` (or `build.gradle`).

## iOS

iOS flavors still require Xcode schemes/build configurations to be set up manually.
Use separate schemes (for example: `dev`, `staging`, `prod`) and point each to the matching Dart target above.
''';

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\-\s]+'))
        .where((e) => e.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
