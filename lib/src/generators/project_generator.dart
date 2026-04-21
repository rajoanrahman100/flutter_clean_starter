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
    };

    for (final entry in flavorFiles.entries) {
      final file = File(p.join(projectDir.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }

    Console.success('Flavor config written.');
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
}
''';

  String _flavorEnum() => '''
enum Flavor { dev, staging, prod }
''';
}